import { api, wire, LightningElement, track } from "lwc";
import { FlowAttributeChangeEvent, FlowNavigationFinishEvent  } from 'lightning/flowSupport';

export default class OpenUrlFromFlow extends LightningElement {
    @api 
    urlParam;

    @api
    targetParam;
    
    @api
    connectedCallback(){
        if(this.targetParam.replace('_','') == 'subtab'){
            this.openSubtab();
        } else {
            this.openWindow(this.targetParam);
        }
        const navigateFinishEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateFinishEvent);
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
          const apiEvent = new CustomEvent("internalapievent", {
            bubbles: true,
            composed: true,
            cancelable: false,
            detail: {
              category: "workspaceAPI",
              methodName: methodName,
              methodArgs: methodArgs,
              callback: (err, response) => {
                if (err) {
                    return reject(err);
                } else {
                    return resolve(response);
                }
              }
            }
          });
     
          window.dispatchEvent(apiEvent);
        });
    }

    openSubtab() {
        this.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
          if (isConsole) {
            this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
              console.log('tabId: '+focusedTab.tabId);
              //console.log(JSON.stringify(focusedTab));
              this.invokeWorkspaceAPI('openSubtab', {
                parentTabId: focusedTab.tabId,
                url: this.urlParam,
                focus: true
              });
            //   .then(tabId => {
            //     console.log("Solution #2 - SubTab ID: ", tabId);
            //     this.closeDetails();
            //   });
            });
          } else {
            this.openWindow('_self');
          }
        });
    }

    openWindow(target){
        window.open(this.urlParam, target);
    }
}