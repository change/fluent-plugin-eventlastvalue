class Fluent::EventLastValueOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('eventlastvalue', self)
  def initialize
    super
  end

  # Define `router` method of v0.12 to support v0.10 or earlier
  unless method_defined?(:router)
    define_method("router") { Fluent::Engine }
  end

  config_param :emit_to, :string, :default => 'debug.events'
  config_param :id_key, :string, :default => 'id'
  config_param :last_value_key, :string, :default => nil
  config_param :comparator_key, :string, :default => nil

  attr_accessor :last_values

  def configure(conf)
    super
  end

  def start
    super
  end

  def format(tag, time, record)
    return '' unless @last_value_key.nil? || record[@last_value_key]
    [record[@id_key], record, (record[@comparator_key] || 0).to_f].to_json + "\n"
  end

  def write(chunk)
    last_values = Hash.new {|hash, key| hash[key] = Hash.new {|h,k| h[k] = nil } }
    last_times = Hash.new {|hash, key| hash[key] = 0}
    chunk.open do |io|
      items = io.read.split("\n")
      items.each do |item|
        key, event, t = JSON.parse(item)
        if @comparator_key.nil? || last_times[key] < t
          last_times[key] = t
          last_values[key] = event
        end
      end
    end

    last_values.each do |key, last_record|
      router.emit(@emit_to, Time.now.to_i, last_record)
    end
  end
end
