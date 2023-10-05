import {
  DynamoDBClient,
  GetItemCommand,
  GetItemCommandOutput,
} from '@aws-sdk/client-dynamodb';
import { APIGatewayEvent, APIGatewayProxyResultV2 } from 'aws-lambda';
import { APIGatewaySimpleAuthorizerResult } from 'aws-lambda/trigger/api-gateway-authorizer';

export const handler = async (
  event: APIGatewayEvent,
): Promise<APIGatewayProxyResultV2<APIGatewaySimpleAuthorizerResult>> => {
  try {
    const apiKey: string | undefined = event.headers['x-api-key'];

    if (apiKey == null) return { isAuthorized: false };

    const client: DynamoDBClient = new DynamoDBClient();
    const input = {
      Key: { key: { S: apiKey } },
      TableName: 'cartographie-nationale.api-keys',
    };
    const command: GetItemCommand = new GetItemCommand(input);
    const response: GetItemCommandOutput = await client.send(command);

    return {
      isAuthorized: response.Item != null,
    };
  } catch (err) {
    console.log(err);
  }
};
