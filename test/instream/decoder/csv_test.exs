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

  describe "error responses" do
    test "minimal response" do
      response = """
      error
      unable to parse authentication credentials
      """

      assert [%{"error" => "unable to parse authentication credentials"}] = CSV.parse(response)
    end

    test "full response" do
      response = """
      #datatype,string,long
      ,error,reference
      ,Failed to parse query,897
      """

      assert [%{"error" => "Failed to parse query", "reference" => 897}] = CSV.parse(response)
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

    test "response without values" do
      response = """
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,double,string,string,boolean,string\ŗ
      result,table,_start,_stop,_time,_value,_field,_measurement,region_east,host\r
      """

      assert [] = CSV.parse(response)
    end
  end

  describe "datatype mapping" do
    test "boolean" do
      response = """
      #datatype,string,boolean\r
      type,value\r
      boolean,true\r
      boolean,false\r
      boolean,\r
      """

      assert [
               %{
                 "type" => "boolean",
                 "value" => true
               },
               %{
                 "type" => "boolean",
                 "value" => false
               },
               %{
                 "type" => "boolean",
                 "value" => nil
               }
             ] = CSV.parse(response)
    end

    test "dateTime:RFC3339" do
      response = """
      #datatype,string,dateTime:RFC3339\r
      type,value\r
      dateTime:RFC3339,2018-05-08T20:50:00Z\r
      dateTime:RFC3339,\r
      """

      assert [
               %{
                 "type" => "dateTime:RFC3339",
                 "value" => 1_525_812_600_000_000_000
               },
               %{
                 "type" => "dateTime:RFC3339",
                 "value" => nil
               }
             ] = CSV.parse(response)
    end

    test "dateTime:RFC3339Nano" do
      response = """
      #datatype,string,dateTime:RFC3339Nano\r
      type,value\r
      dateTime:RFC3339Nano,2018-05-08T20:50:00.100200000Z\r
      dateTime:RFC3339Nano,\r
      """

      assert [
               %{
                 "type" => "dateTime:RFC3339Nano",
                 "value" => 1_525_812_600_100_200_000
               },
               %{
                 "type" => "dateTime:RFC3339Nano",
                 "value" => nil
               }
             ] = CSV.parse(response)
    end

    test "double" do
      response = """
      #datatype,string,double\r
      type,value\r
      double,10.20\r
      double,\r
      """

      assert [
               %{
                 "type" => "double",
                 "value" => 10.20
               },
               %{
                 "type" => "double",
                 "value" => nil
               }
             ] = CSV.parse(response)
    end

    test "long" do
      response = """
      #datatype,string,long\r
      type,value\r
      long,100\r
      long,\r
      """

      assert [
               %{
                 "type" => "long",
                 "value" => 100
               },
               %{
                 "type" => "long",
                 "value" => nil
               }
             ] = CSV.parse(response)
    end

    test "string" do
      response = """
      #datatype,string,string\r
      type,value\r
      string,some-value\r
      string,\r
      """

      assert [
               %{
                 "type" => "string",
                 "value" => "some-value"
               },
               %{
                 "type" => "string",
                 "value" => nil
               }
             ] = CSV.parse(response)
    end

    test "unsignedLong" do
      response = """
      #datatype,string,unsignedLong\r
      type,value\r
      unsignedLong,100\r
      unsignedLong,\r
      """

      assert [
               %{
                 "type" => "unsignedLong",
                 "value" => 100
               },
               %{
                 "type" => "unsignedLong",
                 "value" => nil
               }
             ] = CSV.parse(response)
    end
  end
end
