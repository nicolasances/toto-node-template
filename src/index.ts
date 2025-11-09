import { TotoAPIController } from "toto-api-controller";
import { ControllerConfig } from "./Config";

const api = new TotoAPIController(new ControllerConfig({ apiName: "toto-ms-ex1" }), { basePath: '/ex1' });

// api.path('POST', '/something', new PostSomething())

api.init().then(() => {
    api.listen()
});