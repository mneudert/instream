defmodule Instream.Decoder.LineTest do
  use ExUnit.Case

  alias Instream.Decoder.CSV

  describe "with datatype annotation" do
    test "single schema decoding" do
      response = """
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,double,string,string,boolean,string\r
      #default,my-result,,,,,,,,,\r
      #group,false,false,true,true,false,true,true,true,true,true\r
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,15.43,value,cpu,true,A\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,59.25,value,cpu,true,B\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,52.62,value,cpu,true,C\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,62.73,value,cpu,false,A\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,12.83,value,cpu,false,B\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,51.62,value,cpu,false,C\r
      \r
      """

      assert [
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_600_000_000_000,
                 "_value" => 15.43,
                 "host" => "A",
                 "region_east" => true,
                 "result" => "my-result",
                 "table" => 0
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_620_000_000_000,
                 "_value" => 59.25,
                 "host" => "B",
                 "region_east" => true,
                 "result" => "my-result",
                 "table" => 0
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_640_000_000_000,
                 "_value" => 52.62,
                 "host" => "C",
                 "region_east" => true,
                 "result" => "my-result",
                 "table" => 0
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_600_000_000_000,
                 "_value" => 62.73,
                 "host" => "A",
                 "region_east" => false,
                 "result" => "my-result",
                 "table" => 1
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_620_000_000_000,
                 "_value" => 12.83,
                 "host" => "B",
                 "region_east" => false,
                 "result" => "my-result",
                 "table" => 1
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_640_000_000_000,
                 "_value" => 51.62,
                 "host" => "C",
                 "region_east" => false,
                 "result" => "my-result",
                 "table" => 1
               }
             ] = CSV.parse(response)
    end

    test "multiple schema decoding" do
      response = """
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,double,string,string,boolean,string\r
      #default,my-result,,,,,,,,,\r
      #group,false,false,true,true,false,true,true,true,true,true\r
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      ,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,15.43,value,cpu,true,A\r
      \r
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,double,string,string,boolean,string\r
      #default,my-result,,,,,,,,,\r
      #group,false,false,true,true,false,true,true,true,true,true\r
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      ,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,62.73,value,cpu,false,A\r
      \r
      """

      assert [
               [
                 %{
                   "_field" => "value",
                   "_measurement" => "cpu",
                   "_start" => 1_525_812_600_000_000_000,
                   "_stop" => 1_525_812_660_000_000_000,
                   "_time" => 1_525_812_600_000_000_000,
                   "_value" => 15.43,
                   "host" => "A",
                   "region_east" => true,
                   "result" => "my-result",
                   "table" => 0
                 }
               ],
               [
                 %{
                   "_field" => "value",
                   "_measurement" => "cpu",
                   "_start" => 1_525_812_600_000_000_000,
                   "_stop" => 1_525_812_660_000_000_000,
                   "_time" => 1_525_812_600_000_000_000,
                   "_value" => 62.73,
                   "host" => "A",
                   "region_east" => false,
                   "result" => "my-result",
                   "table" => 1
                 }
               ]
             ] = CSV.parse(response)
    end
  end

  describe "without datatype annotation" do
    test "single schema decoding" do
      response = """
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,15.43,value,cpu,true,A\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,59.25,value,cpu,true,B\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,52.62,value,cpu,true,C\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,62.73,value,cpu,false,A\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,12.83,value,cpu,false,B\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,51.62,value,cpu,false,C\r
      \r
      """

      assert [
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:00Z",
                 "_value" => "15.43",
                 "host" => "A",
                 "region_east" => "true",
                 "result" => "my-result",
                 "table" => "0"
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:20Z",
                 "_value" => "59.25",
                 "host" => "B",
                 "region_east" => "true",
                 "result" => "my-result",
                 "table" => "0"
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:40Z",
                 "_value" => "52.62",
                 "host" => "C",
                 "region_east" => "true",
                 "result" => "my-result",
                 "table" => "0"
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:00Z",
                 "_value" => "62.73",
                 "host" => "A",
                 "region_east" => "false",
                 "result" => "my-result",
                 "table" => "1"
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:20Z",
                 "_value" => "12.83",
                 "host" => "B",
                 "region_east" => "false",
                 "result" => "my-result",
                 "table" => "1"
               },
               %{
                 "_field" => "value",
                 "_measurement" => "cpu",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:40Z",
                 "_value" => "51.62",
                 "host" => "C",
                 "region_east" => "false",
                 "result" => "my-result",
                 "table" => "1"
               }
             ] = CSV.parse(response)
    end

    test "multiple schema decoding" do
      response = """
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,15.43,value,cpu,true,A\r
      \r
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,62.73,value,cpu,false,A\r
      \r
      """

      assert [
               [
                 %{
                   "_field" => "value",
                   "_measurement" => "cpu",
                   "_start" => "2018-05-08T20:50:00Z",
                   "_stop" => "2018-05-08T20:51:00Z",
                   "_time" => "2018-05-08T20:50:00Z",
                   "_value" => "15.43",
                   "region_east" => "true",
                   "result" => "my-result",
                   "host" => "A",
                   "table" => "0"
                 }
               ],
               [
                 %{
                   "_field" => "value",
                   "_measurement" => "cpu",
                   "_start" => "2018-05-08T20:50:00Z",
                   "_stop" => "2018-05-08T20:51:00Z",
                   "_time" => "2018-05-08T20:50:00Z",
                   "_value" => "62.73",
                   "host" => "A",
                   "region_east" => "false",
                   "result" => "my-result",
                   "table" => "1"
                 }
               ]
             ] = CSV.parse(response)
    end
  end

  describe "empty or broken responses" do
    test "empty responses" do
      assert [] = CSV.parse("")
      assert [] = CSV.parse("\r")
      assert [] = CSV.parse("\n")
      assert [] = CSV.parse("\r\n")
      assert [] = CSV.parse("\r\n\r")
      assert [] = CSV.parse("\r\n\n")
      assert [] = CSV.parse("\r\n\r\n")
    end

    test "header only response" do
      response = """
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      """

      assert [] = CSV.parse(response)
    end

    test "annotation only response" do
      response = """
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,double,string,string,boolean,string\ŗ
      """

      assert [] = CSV.parse(response)
    end
  end
end
