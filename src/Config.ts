import { APIOptions, TotoControllerConfig } from 'totoms';

const dbName = 'mydb';
const collections = {
    coll1: 'coll1',
};

export class ControllerConfig extends TotoControllerConfig {

    getMongoSecretNames(): { userSecretName: string; pwdSecretName: string; } | null {
        return null;
    }

    getProps(): APIOptions {
        return {}
    }

}
