global class AggregateResultIterable implements Iterable<AggregateResult> {
  private String query;
  private List<Date> listDateCheck;

  global AggregateResultIterable(String soql,List<Date> dateList){
    query = soql;
    listDateCheck = dateList;   
      
  }

  global Iterator<AggregateResult> Iterator(){
    return new AggregateResultIterator(query,listDateCheck);
  }
}