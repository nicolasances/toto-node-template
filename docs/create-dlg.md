# Creating a Delegate in Toto

A Delegate, in a Toto API, is just a class that handles an HTTP request and corresponds to an endpoint. <br>
A Delegate implements `TotoDelegate`

An example of Delegate implementation is the following: 
```
import { Request } from "express";
import { ExecutionContext, TotoDelegate, TotoRuntimeError, UserContext, ValidationError } from "toto-api-controller";
import { ControllerConfig } from "../Config";


/**
 * This Delegate starts a new practice.
 */
export class PostExpense implements TotoDelegate {

    async do(req: Request, userContext: UserContext, execContext: ExecutionContext): Promise<any> {

        const body = req.body
        const logger = execContext.logger;
        const cid = execContext.cid;
        const config = execContext.config as ControllerConfig;

        // Putting a default description
        let description = body.description
        if (!description) description = "Unknown"

        // Validate mandatory fields
        if (!body.amount) throw new ValidationError(400, "No amount provided")

        // Extract user
        const user = userContext.email;

        let client;

        try {

            // Instantiate the DB
            client = await config.getMongoClient();
            const db = client.db(config.getDBName());

            // Do something 

            // Return something
            return {  }


        } catch (error) {

            logger.compute(cid, `${error}`, "error")

            if (error instanceof ValidationError || error instanceof TotoRuntimeError) {
                throw error;
            }
            else {
                console.log(error);
                throw error;
            }

        }
        finally {
            if (client) client.close();
        }

    }

}
```