// Node.js Azure Function sample (HTTP trigger) to forward payload to Service Bus
// Replace process.env.SERVICEBUS_CONNECTION with the namespace connection string and SERVICEBUS_TOPIC with topic name

const { ServiceBusClient } = require('@azure/service-bus');

module.exports = async function (context, req) {
  const payload = req.body || {};
  const sbConn = process.env.SERVICEBUS_CONNECTION;
  const topic = process.env.SERVICEBUS_TOPIC || 'bookings';
  if (!sbConn) {
    context.log('Missing SERVICEBUS_CONNECTION');
    context.res = { status: 500, body: 'Missing service bus connection' };
    return;
  }

  const client = new ServiceBusClient(sbConn);
  const sender = client.createSender(topic);
  try {
    await sender.sendMessages({ body: payload });
    context.res = { status: 200, body: { sent: true } };
  } catch (err) {
    context.log.error(err);
    context.res = { status: 500, body: err.message };
  } finally {
    await sender.close();
    await client.close();
  }
};
