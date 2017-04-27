module Utils
  module LitaWhoHas
    # Utility methods for working with Lita's Redis
    module Persistence
      private

      def key(thing_id)
        ['whohas_things', config.namespace, thing_id].join(':')
      end

      def description(thing_id)
        value = redis.hget(key(thing_id), 'description')
        value && !value.empty? ? JSON.parse(value) : {}
      end

      def describe(thing_id, dkey, dvalue)
        new_desc = description(thing_id).merge(dkey => dvalue)
        redis.hset(key(thing_id), 'description', new_desc.to_json)
      end

      def current_user(thing_id)
        redis.hget(key(thing_id), 'user')
      end

      def full_description_json(thing_id)
        JSON.pretty_generate(
          { 'in use by' => current_user(thing_id) }.merge(description(thing_id))
        )
      end
    end
  end
end
