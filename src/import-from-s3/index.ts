import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import {
  DeleteCommand,
  DeleteCommandOutput,
  DynamoDBDocumentClient,
  PutCommand,
  PutCommandOutput,
  ScanCommand,
  ScanCommandOutput,
} from '@aws-sdk/lib-dynamodb';
import { APIGatewayProxyResultV2 } from 'aws-lambda';
import { S3Event } from 'aws-lambda/trigger/s3';

type UploadToS3Info = {
  bucket: string;
  key: string;
};

const s3Client: S3Client = new S3Client();

const removeAllItemsFrom =
  (docClient: DynamoDBDocumentClient) =>
  async (tableName: string): Promise<void> => {
    let ExclusiveStartKey = undefined;

    do {
      console.log('Getting a batch of items to delete');
      const scanCommand: ScanCommand = new ScanCommand({
        ProjectionExpression: 'id',
        TableName: tableName,
        ConsistentRead: true,
        ExclusiveStartKey,
      });

      const dynamoDBResponse: ScanCommandOutput =
        await docClient.send(scanCommand);

      console.log('Deleting batch of items');
      await Promise.all(
        dynamoDBResponse.Items.map(
          async (item): Promise<DeleteCommandOutput> =>
            docClient.send(
              new DeleteCommand({ TableName: tableName, Key: { id: item.id } }),
            ),
        ),
      );

      ExclusiveStartKey = dynamoDBResponse.LastEvaluatedKey;
    } while (ExclusiveStartKey);
  };

const importAllItemsFrom =
  (docClient: DynamoDBDocumentClient) =>
  async (itemsToImport: object[], tableName: string): Promise<void> => {
    console.log(`Writing ${itemsToImport.length} items`);

    for (let i = 0; i < itemsToImport.length; i++) {
      if (i % 1000 === 0) {
        console.log(
          `Writing items ${i + 1} to ${Math.min(
            i + 1000,
            itemsToImport.length,
          )} of ${itemsToImport.length}`,
        );
      }
      await docClient.send(
        new PutCommand({ TableName: tableName, Item: itemsToImport[i] }),
      );
    }
  };

const tableNameFromJsonFile = (key: string): string => key.replace('.json', '');

const readJsonFromS3 = async ({
  key,
  bucket,
}: UploadToS3Info): Promise<object[]> =>
  JSON.parse(
    await (
      await s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: key }))
    ).Body.transformToString(),
  );

const successResponseForImportTo = (
  tableName: string,
): APIGatewayProxyResultV2 => ({
  statusCode: 200,
  body: `All items that were uploaded to the bucket have been successfully imported into the ${tableName} dynamo table`,
});

const getUploadToS3Info = ({ Records }: S3Event): UploadToS3Info => ({
  bucket: Records[0].s3.bucket.name,
  key: decodeURIComponent(Records[0].s3.object.key.replace(/\+/g, ' ')),
});

export const handler = async (
  s3Event: S3Event,
): Promise<APIGatewayProxyResultV2> => {
  const uploadToS3Info: UploadToS3Info = getUploadToS3Info(s3Event);
  const tableName: string = tableNameFromJsonFile(uploadToS3Info.key);
  const docClient: DynamoDBDocumentClient = DynamoDBDocumentClient.from(
    new DynamoDBClient(),
  );

  try {
    await removeAllItemsFrom(docClient)(tableName);
    const itemsToImport: object[] = await readJsonFromS3(uploadToS3Info);
    await importAllItemsFrom(docClient)(itemsToImport, tableName);

    return successResponseForImportTo(tableName);
  } catch (err) {
    console.log(err);
  }
};
