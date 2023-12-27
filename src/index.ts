import { TotoAPIController } from "toto-api-controller";
import { ControllerConfig } from "./Config";

const api = new TotoAPIController("my-microservice", new ControllerConfig())

// api.path('POST', '/something', new PostSomething())

api.init().then(() => {
    api.listen()
});