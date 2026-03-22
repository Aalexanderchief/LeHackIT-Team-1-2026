import mdns from "multicast-dns";

export function startMdnsAdvertiser(port: number): () => void {
  const service = mdns();

  service.on("query", (query) => {
    const asksForService = query.questions.some((q) =>
      q.name === "_lehackit-controller._udp.local"
    );

    if (!asksForService) {
      return;
    }

    service.respond({
      answers: [
        {
          name: "_lehackit-controller._udp.local",
          type: "SRV",
          ttl: 120,
          data: {
            port,
            priority: 0,
            weight: 0,
            target: "lehackit-server.local"
          }
        }
      ]
    });
  });

  return () => service.destroy();
}
