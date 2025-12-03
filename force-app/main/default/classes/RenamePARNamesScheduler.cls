global class RenamePARNamesScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        SysUtils.renamePARNames();
    }
}