require 'spec_helper'

describe Fluent::EventLastValueOutput do
  before { Fluent::Test.setup }


  describe '#format' do
    let (:conf) {
      %[
        emit_to output.lastvalue
        id_key id
        comparator_key timestamp
        last_value_key count
      ]
    }
    let (:eventlastvalue) { Fluent::Test::BufferedOutputTestDriver.new(Fluent::EventLastValueOutput.new).configure(conf) }
    context 'the input contains the last_value key' do
      it 'produces the expected output' do
        record = { 'id' => '4444', 'timestamp' => 123456789, 'count' => 12345 }

        eventlastvalue.tag = 'something'
        eventlastvalue.emit( record, Time.now )
        eventlastvalue.expect_format ["4444", record, record['timestamp'].to_f].to_json + "\n"
        eventlastvalue.run
      end
    end

    context 'the input does not contain the last_value_key' do
      it 'does not add it to the buffer' do
        eventlastvalue.tag = 'something'
        eventlastvalue.emit( { 'not_last_value_key' => 12345}, Time.now )
        eventlastvalue.expect_format ''
        eventlastvalue.run
      end
    end
  end

  describe 'output' do
    let (:conf) {
      %[
        emit_to output.lastvalue
        id_key input_id
        last_value_key count
        comparator_key timestamp
      ]
    }
    let (:input) {
      %[{"email": "john.doe@example.com", "count": 12345, "timestamp": "1", "input_id": "1234"}
        {"email": "john.doe@example.com", "count": 12340, "timestamp": "6", "input_id": "1234"}
        {"email": "john.doe@example.com", "count": 12346, "timestamp": "2", "input_id": "1234"}
        {"email": "john.doe@example.com", "count": 12344, "timestamp": "3", "input_id": "1234"}
        {"email": "john.doe@example.com", "count": 12342, "timestamp": "4", "input_id": "1234"}
        {"email": "john.doe@example.com", "count": 12349, "timestamp": "5", "input_id": "1234"}]
    }
    let (:eventlastvalue) { Fluent::Test::BufferedOutputTestDriver.new(Fluent::EventLastValueOutput.new).configure(conf) }

    context "a comparator key is specified" do
      it "formats the lastvalue against the provided tag" do
        line = input.split("\n").first
        data = JSON.parse line
        eventlastvalue.emit data, Time.now
        output = eventlastvalue.run
        expect(output['1234']).to eq data
      end

      it "returns the latest count given the comparator key" do
        input.split("\n").each do |line|
          data = JSON.parse line
          eventlastvalue.emit data, Time.now
        end
        expected = {"email" => "john.doe@example.com", "count" => 12340, "timestamp" => "6", "input_id" => "1234"}
        output = eventlastvalue.run
        expect(output['1234']).to eq expected
      end
    end

    context "a comparator key is NOT specified" do
      let (:conf) {
        %[
          emit_to output.lastvalue
          id_key input_id
          last_value_key count
        ]
      }

      let (:eventlastvalue) { Fluent::Test::BufferedOutputTestDriver.new(Fluent::EventLastValueOutput.new).configure(conf) }
      it "returns the last received count" do
        input.split("\n").each do |line|
          data = JSON.parse line
          eventlastvalue.emit data, Time.now
        end
        expected = {"email"=>"john.doe@example.com", "count"=>12349, "timestamp"=>"5", "input_id"=>"1234"}
        output = eventlastvalue.run
        expect(output['1234']).to eq expected
      end
    end
  end
end
