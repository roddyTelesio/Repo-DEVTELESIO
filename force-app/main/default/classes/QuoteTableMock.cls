global with sharing class QuoteTableMock implements HttpCalloutMock{
    

    global Integer statusCode; 
    global String body; 

    global QuoteTableMock(Integer statusCode, String body) {
        this.statusCode = statusCode; 
        this.body = body; 
    }


    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.body);
        res.setStatusCode(this.statusCode);
        return res;
    }

}