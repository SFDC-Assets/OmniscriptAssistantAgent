import { OmniscriptBaseActionUtil } from './omniscriptBaseActionUtil';
import { handleExtraPayload } from 'c/omniscriptInternalUtils';

/**
 * Omniscript Delete Action Utility Class
 */
export class OmniscriptDeleteActionUtil extends OmniscriptBaseActionUtil {
    preProcess(params, queueableRespId, comp, payload, vlcParams) {
        let inputParams = {};
        inputParams.propSetMap = Object.assign({}, this._element.propSetMap);
        inputParams.propSetMap.deleteSObject = handleExtraPayload(inputParams.propSetMap.deleteSObject, [], comp, this.getCompJsonData(comp));
        return this.preProcessCommonReq(
            comp,
            this._element,
            {
                sClassName: `${this._ns}IPService`,
                sMethodName: 'vlcOmniScriptDeleteAction',
            },
            inputParams,
            vlcParams,
        );
    }
}
