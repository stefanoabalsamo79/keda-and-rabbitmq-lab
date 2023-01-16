// const amqp = require('amqplib/callback_api');

// const { RABBIT_USERNAME, RABBIT_PASSWORD, RABBIT_SVC_IP_PORT, QUEUE_NAME } = process.env

// console.log({ RABBIT_USERNAME, RABBIT_PASSWORD, RABBIT_SVC_IP_PORT, QUEUE_NAME })

// const opt = { 
//   credentials: require('amqplib').credentials.plain(RABBIT_USERNAME, RABBIT_PASSWORD) 
// }

// amqp.connect(`amqp://${RABBIT_SVC_IP_PORT}`, opt, function(error0, connection) {
//   if (error0) throw error0
//   connection.createChannel(function(error1, channel) {
//     if (error1) throw error1
//     const queue = QUEUE_NAME
//     let i = 1
//     setInterval(()=> {
//       const msg = `msg n. ${i++}`
//       channel.assertQueue(queue, { durable: true })
//       channel.sendToQueue(queue, Buffer.from(msg))
//       console.log('Sent: ', msg)
//     }, 10)

//   })
// })

const amqp = require('amqplib/callback_api');

const { RABBIT_USERNAME, RABBIT_PASSWORD, RABBIT_SVC_IP_PORT, QUEUE_NAME } = process.env

console.log({ RABBIT_USERNAME, RABBIT_PASSWORD, RABBIT_SVC_IP_PORT, QUEUE_NAME })

const opt = { 
  credentials: require('amqplib').credentials.plain(RABBIT_USERNAME, RABBIT_PASSWORD) 
}

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
      console.log("Sending messages. To exit press CTRL+C")
      let i = 1
      setInterval(() => {
        const msg = `msg n. ${i++}`
        channel.sendToQueue(queue, Buffer.from(msg))
        console.log('Sent: ', msg)
      }, 100)
    })
  })
})

const beKind = (err, connection) => {
  console.error(err)
  if (connection) connection.close(() => {
    process.exit(1)
  })
}