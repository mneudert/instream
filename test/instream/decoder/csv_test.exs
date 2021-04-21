defmodule Instream.Decoder.LineTest do
  use ExUnit.Case

  alias Instream.Decoder.CSV

  describe "with datatype annotation" do
    test "single schema decoding" do
      response = """
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,boolean,string,double
      #default,my-result,,,,,,,\r
      #group,false,false,true,true,false,true,true,true\r
      result,table,_start,_stop,_time,region_east,host,_value\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,true,A,15.43\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,true,B,59.25\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,true,C,52.62\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,false,A,62.73\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,false,B,12.83\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,false,C,51.62\r
      \r
      """

      assert [
               %{
                 "result" => "my-result",
                 "table" => 0,
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_600_000_000_000,
                 "region_east" => true,
                 "host" => "A",
                 "_value" => 15.43
               },
               %{
                 "result" => "my-result",
                 "table" => 0,
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_620_000_000_000,
                 "region_east" => true,
                 "host" => "B",
                 "_value" => 59.25
               },
               %{
                 "result" => "my-result",
                 "table" => 0,
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_640_000_000_000,
                 "region_east" => true,
                 "host" => "C",
                 "_value" => 52.62
               },
               %{
                 "result" => "my-result",
                 "table" => 1,
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_600_000_000_000,
                 "region_east" => false,
                 "host" => "A",
                 "_value" => 62.73
               },
               %{
                 "result" => "my-result",
                 "table" => 1,
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_620_000_000_000,
                 "region_east" => false,
                 "host" => "B",
                 "_value" => 12.83
               },
               %{
                 "result" => "my-result",
                 "table" => 1,
                 "_start" => 1_525_812_600_000_000_000,
                 "_stop" => 1_525_812_660_000_000_000,
                 "_time" => 1_525_812_640_000_000_000,
                 "region_east" => false,
                 "host" => "C",
                 "_value" => 51.62
               }
             ] = CSV.parse(response)
    end

    test "multiple schema decoding" do
      response = """
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,boolean,string,double
      #default,my-result,,,,,,,\r
      #group,false,false,true,true,false,true,true,true\r
      result,table,_start,_stop,_time,region_east,host,_value\r
      ,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,true,A,15.43\r
      \r
      #datatype,string,long,dateTime:RFC3339,dateTime:RFC3339,dateTime:RFC3339,boolean,string,double
      #default,my-result,,,,,,,\r
      #group,false,false,true,true,false,true,true,true\r
      result,table,_start,_stop,_time,region_east,host,_value\r
      ,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,false,A,62.73\r
      \r
      """

      assert [
               [
                 %{
                   "result" => "my-result",
                   "table" => 0,
                   "_start" => 1_525_812_600_000_000_000,
                   "_stop" => 1_525_812_660_000_000_000,
                   "_time" => 1_525_812_600_000_000_000,
                   "region_east" => true,
                   "host" => "A",
                   "_value" => 15.43
                 }
               ],
               [
                 %{
                   "result" => "my-result",
                   "table" => 1,
                   "_start" => 1_525_812_600_000_000_000,
                   "_stop" => 1_525_812_660_000_000_000,
                   "_time" => 1_525_812_600_000_000_000,
                   "region_east" => false,
                   "host" => "A",
                   "_value" => 62.73
                 }
               ]
             ] = CSV.parse(response)
    end
  end

  describe "without datatype annotation" do
    test "single schema decoding" do
      response = """
      result,table,_start,_stop,_time,region_east,host,_value\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,true,A,15.43\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,true,B,59.25\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,true,C,52.62\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,false,A,62.73\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:20Z,false,B,12.83\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:40Z,false,C,51.62\r
      \r
      """

      assert [
               %{
                 "result" => "my-result",
                 "table" => "0",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:00Z",
                 "region_east" => "true",
                 "host" => "A",
                 "_value" => "15.43"
               },
               %{
                 "result" => "my-result",
                 "table" => "0",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:20Z",
                 "region_east" => "true",
                 "host" => "B",
                 "_value" => "59.25"
               },
               %{
                 "result" => "my-result",
                 "table" => "0",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:40Z",
                 "region_east" => "true",
                 "host" => "C",
                 "_value" => "52.62"
               },
               %{
                 "result" => "my-result",
                 "table" => "1",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:00Z",
                 "region_east" => "false",
                 "host" => "A",
                 "_value" => "62.73"
               },
               %{
                 "result" => "my-result",
                 "table" => "1",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:20Z",
                 "region_east" => "false",
                 "host" => "B",
                 "_value" => "12.83"
               },
               %{
                 "result" => "my-result",
                 "table" => "1",
                 "_start" => "2018-05-08T20:50:00Z",
                 "_stop" => "2018-05-08T20:51:00Z",
                 "_time" => "2018-05-08T20:50:40Z",
                 "region_east" => "false",
                 "host" => "C",
                 "_value" => "51.62"
               }
             ] = CSV.parse(response)
    end

    test "multiple schema decoding" do
      response = """
      result,table,_start,_stop,_time,region_east,host,_value\r
      my-result,0,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,true,A,15.43\r
      \r
      result,table,_start,_stop,_time,region_east,host,_value\r
      my-result,1,2018-05-08T20:50:00Z,2018-05-08T20:51:00Z,2018-05-08T20:50:00Z,false,A,62.73\r
      \r
      """

      assert [
               [
                 %{
                   "result" => "my-result",
                   "table" => "0",
                   "_start" => "2018-05-08T20:50:00Z",
                   "_stop" => "2018-05-08T20:51:00Z",
                   "_time" => "2018-05-08T20:50:00Z",
                   "region_east" => "true",
                   "host" => "A",
                   "_value" => "15.43"
                 }
               ],
               [
                 %{
                   "result" => "my-result",
                   "table" => "1",
                   "_start" => "2018-05-08T20:50:00Z",
                   "_stop" => "2018-05-08T20:51:00Z",
                   "_time" => "2018-05-08T20:50:00Z",
                   "region_east" => "false",
                   "host" => "A",
                   "_value" => "62.73"
                 }
               ]
             ] = CSV.parse(response)
    end
  end
end
