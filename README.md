fluent-plugin-eventlastvalue
==========================

This plugin is designed to find the last value in a specified key and pass it through as lastvalue as a re-emit. As it's a buffered plugin it will write or re-emit at a (tunable) sane pace.

## Example

Given a set of input like

```
count_stream { 'time': 1413544890, 'count': 28, 'id': 1337 }
count_stream { 'time': 1413544830, 'count': 24, 'id': 33864 }
count_stream { 'time': 1413544860, 'count': 25, 'id': 12345, ... }
count_stream { 'time': 1413544890, 'count': 18, 'id': 40555 }
count_stream { 'time': 1413544830, 'count': 5, 'id': 12345 }
count_stream { 'time': 1413544860, 'count': 6, 'id': 12345 }
```

With a conf like

```
<match count_stream>
    type eventlastvalue
    emit_to output.lastvalue
    id_key id
    comparator_key timestamp
    last_value_key count
    flush_interval 1m
</match>
```

You would get

```
output.lastvalue { 'id': 12345, 'count': 6, 'time': 1413544860 }
output.lastvalue { 'id': 1337, 'count': 28, 'time': 1413544890 }
output.lastvalue { 'id': 33864, 'count': 24, 'time': 1413544830 }
output.lastvalue { 'id': 40555, 'count': 18, 'time': 1413544890 }
```

## Installation

OSX

    /opt/td-agent/embedded/bin/gem install fluent-plugin-eventlastvalue

or

    fluent-gem install fluent-plugin-eventlastvalue


## Configuration

### Parameters

#### Basic

- **id_key** (**default**:id)
    - The key within the record that identifies a group of events to select from.

- **last_value_key** (optional)
    - the key from whose values we want to record the last, if present records sent that do not contain the key will be excluded.

- **emit_to** (optional) - *string*
    - Tag to re-emit with
        - *default: debug.events*
- **comparator_key** (optional)
    - Key to use for numeric comparison, used to ensure that the last received message is the one that is counted. If none is set it will record the last received event.
        - *default: nil

#### Other

- **flush_interval** (optional)
    - Provided from **Fluent::BufferedOutput** time in seconds between flushes
        - *default: 60*
