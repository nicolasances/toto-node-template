# Creating a Delegate in Toto

A Delegate, in a Toto API, is just a class that handles an HTTP request and corresponds to an endpoint. <br>
A Delegate **extends** `TotoDelegate`

An example of Delegate implementation is the following: 

```typescript
import { Request } from "express";
import { TotoDelegate, UserContext } from "totoms";

export class SayHello extends TotoDelegate {

    async do(req: Request, userContext?: UserContext): Promise<any> {
        return { message: "Hello World!" };
    }

}
```