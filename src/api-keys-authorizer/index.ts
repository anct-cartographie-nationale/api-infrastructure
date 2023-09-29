import { APIGatewayProxyResultV2 } from 'aws-lambda';

export const handler = async (): Promise<APIGatewayProxyResultV2<boolean>> => {
  try {
    return false;
  } catch (err) {
    console.log(err);
  }
};
