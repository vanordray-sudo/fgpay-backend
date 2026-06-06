const MikroNode = require('mikronode');

const MIKROTIK_HOST = process.env.MIKROTIK_HOST;
const MIKROTIK_USER = process.env.MIKROTIK_USER;
const MIKROTIK_PASS = process.env.MIKROTIK_PASS;

async function addHotspotUser({ username, password, profile }) {
  const device = new MikroNode(MIKROTIK_HOST);

  const [login] = await device.connect();
  const conn = await login(MIKROTIK_USER, MIKROTIK_PASS);
  const channel = conn.openChannel();

  await channel.write('/ip/hotspot/user/add', {
    '=name': username,
    '=password': password,
    '=profile': profile,
  });

  conn.close();
  return true;
}

async function removeHotspotUser(username) {
  const device = new MikroNode(MIKROTIK_HOST);

  const [login] = await device.connect();
  const conn = await login(MIKROTIK_USER, MIKROTIK_PASS);
  const channel = conn.openChannel();

  await channel.write('/ip/hotspot/user/print', {
    '?.name': username,
  });

  channel.on('done', () => {
    conn.close();
  });

  return true;
}

module.exports = {
  addHotspotUser,
  removeHotspotUser,
};