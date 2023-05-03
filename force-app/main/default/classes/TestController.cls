public with sharing class TestController {
    public String getbaseUrl(){
        return 'url: ' + Site.getPathPrefix();
    }
    public TestController() {

    }
    public TestController(ApexPages.StandardController stdController) {

    }
}