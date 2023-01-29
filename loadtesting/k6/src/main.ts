import ws, { Socket } from "k6/ws";
import { check, sleep } from "k6";
import { makeConnection } from "../libs/socket.io";
import { Counter, Trend } from "k6/metrics";
import { SocketWrapper } from "../libs/SocketWrapper";

export const options = {
  vus: 50,
  duration: "15s",
  tags: {
    testName: "socketsio poc",
  },
};

const ready_success = new Counter("ready_success");
const ready_failure = new Counter("ready_failure");

const match_success = new Counter("match_success");
const match_failure = new Counter("match_failure");

export default function (): void {
  const secure = __ENV.REMOTE == "true" ? true : false;

  const domain = secure
    ? `react-video-call-fjutjsrlaa-uc.a.run.app`
    : `localhost:4000`;

  const sid = makeConnection(domain, secure);

  // Let's do some websockets
  const url = `${
    secure ? "wss" : "ws"
  }://${domain}/socket.io/?EIO=4&transport=websocket&sid=${sid}`;

  let response = ws.connect(url, {}, function (socket) {
    const socketWrapper = new SocketWrapper(socket);

    socketWrapper.setEventMessageHandle("message", (msg: any) => {
      console.log("message:", msg);
    });

    socketWrapper.setEventMessageHandle("myping", (msg: any, callback) => {
      if (callback) callback("k6 myping ack");
    });

    socket.on("close", function close() {
      // console.log("disconnected");
    });

    socket.on("error", function (e) {
      console.log("error", JSON.stringify(e));
      if (e.error() != "websocket: close sent") {
        console.log("An unexpected error occured: ", e.error());
      }
    });

    socket.on("open", function open() {
      socket.send("2probe");
      socket.send("5");
      socket.send("3");

      const readyEvent = () => {
        socketWrapper.setEventMessageHandle("match", (msg: any, callback) => {
          console.log("match", msg);
          match_success.add(1);
          if (callback) callback({});
          // console.log("match:", msg);
        });

        socketWrapper.sendWithAck(
          "ready",
          { test: "looking for ack" },
          5000,
          (isSuccess: boolean, elapsed: number, data: any) => {
            if (isSuccess) ready_success.add(1);
            else ready_failure.add(1);
            // console.log("Ready ack data:", data);
          }
        );
      };

      readyEvent();

      // socket.setInterval(function timeout() {
      //   socket.ping();
      //   console.log('Pinging every 1sec (setInterval test)');
      // }, 1000 * 5);
    });

    socket.setTimeout(function () {
      socket.close();
    }, 1000 * 10);
  });

  check(response, { "status is 101": (r) => r && r.status === 101 });
}
