# frozen_string_literal: true

module AssetCloud
  class ActiveRecordBucket < AssetCloud::Bucket
    class_attribute :key_attribute, :value_attribute
    self.key_attribute = "key"
    self.value_attribute = "value"

    def ls(key = name)
      col = records.connection.quote_column_name(key_attribute)
      records.all(conditions: ["#{col} LIKE ?", "#{key}%"]).map do |r|
        cloud[r.send(key_attribute)]
      end
    end

    def read(key)
      find_record!(key).send(value_attribute)
    end

    def write(key, value)
      record = records.send("find_or_initialize_by_#{key_attribute}", key.to_s)
      record.send("#{value_attribute}=", value)
      record.save!
    end

    def delete(key)
      if (record = find_record(key))
        record.destroy
      end
    end

    def stat(key)
      if (record = find_record(key))
        AssetCloud::Metadata.new(true, record.send(value_attribute).size, record.created_at, record.updated_at)
      else
        AssetCloud::Metadata.new(false)
      end
    end

    protected

    # override to return @cloud.user.assets or some other ActiveRecord Enumerable
    # which responds to .connection, .find, etc.
    #
    # model must have columns for this class's key_attribute and value_attribute,
    # plus created_at and updated_at.
    def records
      raise NotImplementedError
    end

    def find_record(key)
      records.first(conditions: { key_attribute => key.to_s })
    end

    def find_record!(key)
      find_record(key) || raise(AssetCloud::AssetNotFoundError, key)
    end
  end
end
