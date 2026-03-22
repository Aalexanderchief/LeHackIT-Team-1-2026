"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.startMdnsAdvertiser = startMdnsAdvertiser;
const multicast_dns_1 = __importDefault(require("multicast-dns"));
function startMdnsAdvertiser(port) {
    const service = (0, multicast_dns_1.default)();
    service.on("query", (query) => {
        const asksForService = query.questions.some((q) => q.name === "_lehackit-controller._udp.local");
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
