import axios from 'axios';
import https from 'https';
import {
  logResponse,
  getNegative,
  getGatewayHost,
  wait,
  expect,
} from '@support';

const defaultPort = 8100;

const agent = new https.Agent({
  rejectUnauthorized: false,
});

axios.defaults.httpsAgent = agent;

/**
 * Get /status/ready endpoint response
 * @param {number} port - port to use
 * @param {boolean} expect503 - whether to expect 503 response
 */
export const getStatusReadyEndpointResponse = async (
  port = defaultPort,
  expect503 = false
) => {
  const statusUrl = `https://${getGatewayHost()}:${port}/status/ready`;
  const resp = expect503
    ? await getNegative(statusUrl, {}, {}, { rejectUnauthorized: true })
    : await axios(statusUrl);
  return resp;
};

/**
 * Expect /status/ready to return 200 OK
 * @param {number} port - port to use
 */
export const expectStatusReadyEndpointOk = async (port = defaultPort) => {
  const response = await getStatusReadyEndpointResponse(port);
  logResponse(response);
  expect(response.status).to.equal(200);
  expect(response.data.message).to.equal('ready');
};

/**
 * Expect /status/ready to return 503 with given message
 * @param {string} message - message to expect
 * @param {number} port - port to use
 */
export const expectStatusReadyEndpoint503 = async (
  message,
  port = defaultPort
) => {
  const response = await getStatusReadyEndpointResponse(port, true);
  logResponse(response);

  expect(response.status).to.equal(503);
  expect(response.data.message).to.equal(message);
  return response;
};

/**
 * Wait for /status/ready to return given status
 * @param {number} returnStatus - status to wait for
 * @param {number} timeout - timeout in ms
 * @param {number} port - port to use
 */
export const waitForTargetStatus = async (
  returnStatus,
  timeout,
  port = defaultPort
) => {
  let response;
  while (timeout > 0) {
    response = await getStatusReadyEndpointResponse(port, true);
    if (response.status === returnStatus) {
      // log final response
      logResponse(response);
      return true;
    }
    await wait(1000);
    timeout -= 1000;
  }
  // log last response received
  logResponse(response);
  return false;
};
