const amqp = require('amqplib/callback_api');

const { RABBIT_USERNAME, RABBIT_PASSWORD, RABBIT_SVC_IP_PORT, QUEUE_NAME } = process.env

console.log({ RABBIT_USERNAME, RABBIT_PASSWORD, RABBIT_SVC_IP_PORT, QUEUE_NAME })

const opt = { 
  credentials: require('amqplib').credentials.plain(RABBIT_USERNAME, RABBIT_PASSWORD) 
}
const sleep = ms => new Promise(resolve => { setTimeout(resolve, ms)})

amqp.connect(`amqp://${RABBIT_SVC_IP_PORT}`, opt, (err, connection) => {
  if (err) return bail(err)
  connection.createChannel((err, channel) => {
    if (err) return bail(err, connection);
    channel.prefetch(1)
    process.once('SIGINT', () => {
      channel.close(() => {
        connection.close()
      });
    });
    const queue = QUEUE_NAME
    channel.assertQueue(queue, { durable: true }, (err, { queue }) => {
      if (err) return beKind(err, connection)
      channel.consume(queue, async msg => {
        await sleep(150)
        console.log("Received %s", msg.content.toString())
        channel.ack(msg)
      }, { noAck: false })
      console.log("Waiting for messages. To exit press CTRL+C")
    })
  })
})

const beKind = (err, connection) => {
  console.error(err)
  if (connection) connection.close(() => {
    process.exit(1)
  })
}