import { getLogger, getUid } from 'react-video-call-common';
import { Socket } from 'socket.io';
import { mainRedisClient } from './socketio_server';

import * as common from 'react-video-call-common';
import { cleanSocket, registerSocket } from './management';

import { getAuth } from 'firebase-admin/auth';

const logger = getLogger();

export const auth_middleware = async (
  socket: Socket,
  next: (err?: any) => void,
) => {
  const auth: string = socket.handshake?.auth?.auth;

  if (!auth) {
    logger.debug(`Authentication token missing`);
    next(new Error(`Authentication token missing`));
    return;
  }
  if (typeof auth != `string`) {
    logger.debug(`Authentication format error`);
    next(new Error(`Authentication format error`));
    return;
  }
  let uid: string = await getUid(auth).catch((error) => {
    logger.debug(`getUid error: ${error}`);
    next(error);
    return;
  });

  socket.data.auth = uid;

  if (await mainRedisClient.hexists(common.connectedAuthMapName, uid)) {
    logger.debug(`User already connected: ${uid}`);
    next(new Error(`User already connected`));
    return;
  }

  socket.on(`disconnect`, async () => {
    await cleanSocket(uid);
  });

  await registerSocket(socket);

  next();
};
