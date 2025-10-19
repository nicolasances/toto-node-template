import { MongoClient } from 'mongodb';
import { TotoControllerConfig, ValidatorProps, Logger, SecretsManager } from "toto-api-controller";

const dbName = 'mydb';
const collections = {
    coll1: 'coll1',
};

export class ControllerConfig implements TotoControllerConfig {

    logger: Logger | undefined;

    mongoUser: string | undefined;
    mongoPwd: string | undefined;
    mongoHost: string | undefined;
    expectedAudience: string | undefined;
    totoAuthEndpoint: string | undefined;
    jwtSigningKey: string | undefined;


    async load(): Promise<any> {

        const env = process.env.HYPERSCALER == 'aws' ? (process.env.ENVIRONMENT ?? 'dev') : process.env.GCP_PID;
        const hyperscaler = process.env.HYPERSCALER == 'aws' ? 'aws' : 'gcp';

        if (!process.env.ENVIRONMENT) this.logger?.compute("", `No environment provided, loading default configuration`);
        if (!process.env.HYPERSCALER) this.logger?.compute("", `No hyperscaler provided, loading default configuration`);

        this.logger?.compute("", `Loading configuration for environment [${env}] on hyperscaler [${hyperscaler}]`);

        const secretsManager = new SecretsManager(hyperscaler, env!, this.logger!);

        let promises = [];

        promises.push(secretsManager.getSecret('toto-expected-audience').then((value) => {
            this.expectedAudience = value;
        }));

        promises.push(secretsManager.getSecret('jwt-signing-key').then((value) => {
            this.jwtSigningKey = value;
        }));

        // Other possible secrets to load:
        // mongo-host
        // mongo-user
        // mongo-pswd
        
        await Promise.all(promises);

    }

    getSigningKey(): string {
        return String(this.jwtSigningKey);
    }

    getProps(): ValidatorProps {

        return {
            customAuthProvider: "toto",
        }
    }

    async getMongoClient() {

        const mongoUrl = `mongodb://${this.mongoUser}:${this.mongoPwd}@${this.mongoHost}:27017`

        return await new MongoClient(mongoUrl).connect();
    }
    
    getExpectedAudience(): string {
        
        return String(this.expectedAudience)
        
    }

    getDBName() { return dbName }
    getCollections() { return collections }

}
