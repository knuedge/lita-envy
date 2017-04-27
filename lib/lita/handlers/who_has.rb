module Lita
  module Handlers
    # The main handler for the WhoHas plugin
    class WhoHas < Handler
      include Utils::LitaWhoHas::Persistence

      route(
        /\Aclaim ([A-Za-z0-9_]+)\Z/,
        :claim_thing,
        help: { 'claim [THING ID]' => 'Mark thing as in use by you' },
        command: true
      )

      route(
        /\Arelease ([A-Za-z0-9_]+)\Z/,
        :release_thing,
        help: { 'release [THING ID]' => 'Mark thing as available' },
        command: true
      )

      route(
        /\Aclaimables(\s+(\S+))?\Z/,
        :list_things,
        help: { 'claimables <optional glob>' => 'List things' },
        command: true
      )

      route(
        /\Aforget ([A-Za-z0-9_]+)\Z/,
        :forget_thing,
        help: { 'forget [THING ID]' => 'Forget thing' },
        command: true
      )

      route(
        /\Adescribe ([A-Za-z0-9_]+)(\s+([A-Za-z0-9_]+)\s+(.+))?\Z/,
        :describe_thing,
        help: {
          'describe [THING ID]' => 'Report on any details for thing',
          'describe [THING ID] [KEY] [VALUE]' => 'Describe the KEY attribute as VALUE for a thing'
        },
        command: true
      )

      route(
        /\Awrestle ([A-Za-z0-9_]+) from (.*)\Z/,
        :claim_used_thing,
        help: { 'wrestle [THING ID] from [USER]' => 'Steal a thing' },
        command: true
      )

      config :namespace, required: true do
        validate do |value|
          unless value =~ /\A[a-z0-9_]+\Z/
            'can only contain lowercase letters, numbers and underscores'
          end
        end
      end

      def claim_thing(response)
        thing_id = response.matches.first.first
        case current_user(thing_id)
        when nil
          redis.hset(key(thing_id), 'user', response.user.name)
          response.reply t('claim_thing.success')
        when ''
          redis.hset(key(thing_id), 'user', response.user.name)
          response.reply t('claim_thing.success')
        when response.user.name
          response.reply t(
            'claim_thing.failure.thing_in_use_by_user', thing_id: thing_id
          )
        else
          response.reply t(
            'claim_thing.failure.thing_in_use_by_other_user',
            thing_id: thing_id,
            user: current_user(thing_id)
          )
        end
      end

      def release_thing(response)
        thing_id = response.matches.first.first
        case current_user(thing_id)
        when nil
          response.reply t(
            'release_thing.failure.thing_unknown',
            thing_id: thing_id
          )
        when ''
          response.reply t(
            'release_thing.failure.thing_not_in_use_by_user',
            thing_id: thing_id
          )
        when response.user.name
          redis.hset(key(thing_id), 'user', nil)
          response.reply t('release_thing.success')
        else
          response.reply t(
            'release_thing.failure.thing_in_use_by_other_user',
            thing_id: thing_id,
            user: current_user(thing_id)
          )
        end
      end

      def list_things(response)
        list_regex = response.matches.first.last
        list_regex ||= /.*/
        lines = []
        redis.keys(key('*')).sort.each do |key|
          thing_id = key.split(':').last
          user = redis.hget(key, 'user')
          line = thing_id
          line += " (#{user})" unless user.empty?
          lines << line if thing_id.match(list_regex)
        end
        if lines.any?
          response.reply(lines.join("\n"))
        else
          response.reply t('list_things.failure.no_things')
        end
      end

      def forget_thing(response)
        thing_id = response.matches.first.first
        case current_user(thing_id)
        when nil
          response.reply t(
            'forget_thing.failure.thing_unknown',
            thing_id: thing_id
          )
        when ''
          redis.del(key(thing_id))
          response.reply t('forget_thing.success')
        when response.user.name
          response.reply t(
            'forget_thing.failure.thing_in_use_by_user',
            thing_id: thing_id
          )
        else
          response.reply t(
            'forget_thing.failure.thing_in_use_by_other_user',
            thing_id: thing_id,
            user: current_user(thing_id)
          )
        end
      end

      def claim_used_thing(response)
        thing_id, specified_user = response.matches.first
        case current_user(thing_id)
        when nil
          response.reply t(
            'claim_used_thing.failure.thing_unknown',
            thing_id: thing_id
          )
        when ''
          response.reply t(
            'claim_used_thing.failure.thing_not_in_use',
            thing_id: thing_id
          )
        when response.user.name
          response.reply t(
            'claim_used_thing.failure.thing_in_use_by_user',
            thing_id: thing_id
          )
        when specified_user
          redis.hset(key(thing_id), 'user', response.user.name)
          response.reply t('claim_used_thing.success')
        else
          response.reply t(
            'claim_used_thing.failure.thing_in_use_by_user_other',
            thing_id: thing_id,
            user: current_user(thing_id),
            specified_user: specified_user
          )
        end
      end

      def describe_thing(response)
        thing_id, _, attribute, value = response.matches.first
        owner = current_user(thing_id)
        case owner
        when nil
          response.reply t(
            'describe_thing.failure.thing_unknown',
            thing_id: thing_id
          )
        when '', response.user.name
          if attribute && value
            describe(thing_id, attribute, value)
            response.reply t(
              'describe_thing.success', key: attribute, thing_id: thing_id
            )
          else
            response.reply t('describe_thing.description', thing_id: thing_id)
            response.reply('/code ' + full_description_json(thing_id))
          end
        else
          if attribute && value
            response.reply t(
              'describe_thing.failure.thing_in_use_by_other_user',
              thing_id: thing_id,
              user: owner
            )
          else
            response.reply t('describe_thing.description', thing_id: thing_id)
            response.reply('/code ' + full_description_json(thing_id))
          end
        end
      end

      Lita.register_handler(self)
    end
  end
end
