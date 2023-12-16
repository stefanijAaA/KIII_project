import { Manager } from 'socket.io-client'

// "undefined" means the URL will be computed from the `window.location` object
const URL = process.env.NEXT_PUBLIC_SOCKET_URL ?? 'http://localhost:3300'

export const createSocket = () => {
  const manager = new Manager(URL, { transports: ['websocket'] })
  return manager.socket('/')
}
