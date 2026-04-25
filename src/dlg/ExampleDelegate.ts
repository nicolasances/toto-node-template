import { Request } from "express";
import { TotoDelegate, UserContext } from "totoms";

export class SayHello extends TotoDelegate<SayHelloRequest, SayHelloResponse> {

    async do(req: Request, userContext?: UserContext): Promise<SayHelloResponse> {
        return { message: "Hello World!" };
    }

    parseRequest(req: Request): SayHelloRequest {
        return {}
    }

}

interface SayHelloRequest {

}

interface SayHelloResponse {
    message: string;
}