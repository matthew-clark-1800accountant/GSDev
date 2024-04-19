public with sharing class QueueableDeleteLogs implements Queueable {
    public void execute(QueueableContext qc){
        BatchableDeleteLogs batch = new BatchableDeleteLogs();
        Database.executeBatch(batch, 25);
    }
}