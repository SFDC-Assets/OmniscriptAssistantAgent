import omniMessageIn from '@salesforce/messageChannel/omniscriptMessageIn__c';
import omniMessageOut from '@salesforce/messageChannel/omniscriptMessageOut__c';
import { publish, subscribe, createMessageContext, APPLICATION_SCOPE } from 'lightning/messageService';

export default class OmniscriptRestApiCoreUtils {
    constructor() {
        this._actionTable = {};

        this.messageContext = createMessageContext();
        this.subscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                omniMessageOut,
                (message) => this.handleOmniActionPubsubUtil(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    publishToMessageChannel(data) {
        publish(this.messageContext, omniMessageIn, data);
    }

    /**
     * Handles the omniscript core action results and resolves the correct promise
     * @param {Object} event 
     */
    handleOmniActionPubsubUtil(event) {
        // check action table and find id, otherwise do nothing
        if (event?.id != null && event.data != null) {
            this.callPromiseFromTable(event.id, event.data);
        }
    }

    /**
     * Sends data to the omniscript core action utility to handle calling the action 
     * @param {Object} data 
     * @param {Object} callback 
     */
    sendOmniActionPubsub(data, callback) {
        const id = this.generateId();
        // include id in payload to know which callback is called
        data.id = id;
        this.addToActionTable(id, callback);

        this.publishToMessageChannel(data);
    }


    /**
     * Generates a unique id to be used as a hash for this action utility's instance
     * @returns a unique String
     */
    generateId() {
        // replace with better id generation later
        return this.generateUUID();
    }

    /**
     * Generates a unique id
     * @returns a unique String
     */
    generateUUID() {
        let d = Date.now();

        const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
            const r = (d + Math.random() * 16) % 16 | 0;
            d = Math.floor(d / 16);
    
            return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
        });
    
        return uuid;
    }

    /**
     * Store callback function into table mapped to id
     * @param {String} id 
     * @param {Function} callback 
     */
    addToActionTable(id, callback) {
        this._actionTable[id] = callback;
    }

    /**
     * After the action's is finished and returns the result,
     * call the correct promise based on the action id 
     * @param {String} id 
     * @param {Object} result 
     */
    callPromiseFromTable(id, result) {
        try {
            // find promise in table based on id, then attempt to call the promise
            if (id != null && typeof this._actionTable[id] === 'function') {
                this._actionTable[id](result);
                delete this._actionTable[id];
            }
        }
        catch (e) {
            window.console.error('omniscriptRestApiCoreUtils : ' + e);
        }
    }

    createPromiseAction(data) {
        return new Promise((resolve, reject) => {
            const callback = (result) => {
                if(result?.exception) {
                    return reject(result.exception);
                }
                return resolve(result);
            };
            this.sendOmniActionPubsub(data, callback);
        });
    }

    genericInvoke2(config) {
        const data = {
            config: config,
            actionType: "genericInvoke2",
            uuid: config.uuid
        }
        return this.createPromiseAction(data);
    }

    genericInvoke2NoCont(config) {
        const data = {
            config: config,
            actionType: "genericInvoke2NoCont",
            uuid: config.uuid
        }
        return this.createPromiseAction(data);
    }

    linkContentDocument(config) {
        const data = {
            config: config,
            actionType: "linkContentDocument",
            uuid: config.uuid
        }
        return this.createPromiseAction(data);
    }

    deleteOSContentDocument(config) {
        const data = {
            config: config,
            actionType: "deleteOSContentDocument",
            uuid: config.uuid
        }
        return this.createPromiseAction(data);
    }

    isCommunity() {
        if(!this.isInCommunity) {
            const data = {
                config: {},
                actionType: "isCommunity",
            }
            return this.createPromiseAction(data).then((result) => {
                this.isInCommunity = result;
                return this.isInCommunity;
            })
        }
        return Promise.resolve(this.isInCommunity);
    }

    getNewportUrl() {
        if (!this.newportUrl) {
            const data = {
                config: {},
                actionType: "getNewportUrl",
            }
            return this.createPromiseAction(data).then((result) => {
                this.newportUrl = result;
                return this.newportUrl;
            });
        }
        return Promise.resolve(this.newportUrl);
    }
}
