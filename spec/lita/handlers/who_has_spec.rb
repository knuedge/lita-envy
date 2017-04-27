require 'spec_helper'

describe Lita::Handlers::WhoHas, lita_handler: true do
  before(:each) do
    allow(subject.config).to receive(:namespace).and_return('my_project')
  end

  describe 'Routing' do
    it { is_expected.to route_command('claim ENV123').to(:claim_thing) }
    it { is_expected.to route_command('release ENV123').to(:release_thing) }
    it { is_expected.to route_command('claimables').to(:list_things) }
    it { is_expected.to route_command('forget ENV123').to(:forget_thing) }
    it { is_expected.to route_command('wrestle ENV123 from Alicia').to(:claim_used_thing) }
    it { is_expected.to route_command('describe ENV123').to(:describe_thing) }
    it { is_expected.to route_command('describe ENV123 key value').to(:describe_thing) }
  end

  describe 'User claiming thing' do
    context 'when thing is available' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', '')
      end

      it 'should mark thing as in use by user' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('claim ENV123', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to eq('Carl')
      end

      it 'should reply with confirmation' do
        send_command('claim ENV123')
        expect(replies.first).to eq("It's all yours!")
      end
    end

    context 'when thing is unknown to bot' do
      before(:each) do
        subject.redis.del('whohas_things:my_project:ENV123')
      end

      it 'should mark thing as in use by user' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('claim ENV123', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to eq('Carl')
      end

      it 'should reply with confirmation' do
        send_command('claim ENV123')
        expect(replies.first).to eq("It's all yours!")
      end
    end

    context 'when thing is in use by another user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Alicia')
      end

      it 'should leave the thing untouched' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('claim ENV123', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to eq('Alicia')
      end

      it 'should reply with notification' do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Alicia')
        carl = Lita::User.create(123, name: 'Carl')
        send_command('claim ENV123', as: carl)
        expect(replies.first).to eq('Hmm, ENV123 is currently in use by Alicia')
      end
    end

    context 'when thing is already in use by user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Carl')
      end

      it 'should leave the thing untouched' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('claim ENV123', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to eq('Carl')
      end

      it 'should reply with notification' do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Carl')
        carl = Lita::User.create(123, name: 'Carl')
        send_command('claim ENV123', as: carl)
        expect(replies.first).to eq('Hmm, you are already using ENV123')
      end
    end
  end

  describe 'User releasing thing' do
    context 'when thing is in use by user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV234', 'user', 'Alicia')
      end

      it 'should mark thing as available' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV234', 'user')).to be_empty
      end

      it 'should reply with confirmation' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(replies.first).to eq('Thanks!')
      end
    end

    context 'when thing is in use by another user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV234', 'user', 'Carl')
      end

      it 'should leave the thing untouched' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV234', 'user')).to eq('Carl')
      end

      it 'should reply with notification' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(replies.first).to eq('Hmm, you are not currently using ENV234 (Carl is)')
      end
    end

    context 'when thing is not in use' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV234', 'user', '')
      end

      it 'should leave the thing untouched' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV234', 'user')).to eq('')
      end

      it 'should reply with notification' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(replies.first).to eq('Hmm, you are not currently using ENV234')
      end
    end

    context 'when thing is unknown to bot' do
      before(:each) do
        subject.redis.del('whohas_things:my_project:ENV234')
      end

      it 'should leave the thing untouched' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV234', 'user')).to be_nil
      end

      it 'should reply with notification' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('release ENV234', as: alicia)
        expect(replies.first).to eq('Hmm, I do not know about ENV234')
      end
    end
  end

  describe 'User listing things' do
    context 'with things recorded' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV345', 'user', '')
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Alicia')
        subject.redis.hset('whohas_things:my_project:ENV234', 'user', 'Carl')
      end

      it 'should list things' do
        send_command('claimables')
        expect(replies.first.split("\n")).to eq([
                                                  'ENV123 (Alicia)',
                                                  'ENV234 (Carl)',
                                                  'ENV345'
                                                ])
      end
    end

    context 'with no things recorded' do
      it 'should respond with notification' do
        send_command('claimables')
        expect(replies.first).to eq('Hmm, I\'m not tracking anything that matches your query')
      end
    end
  end

  describe 'User removing thing' do
    context 'when thing is available' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV345', 'user', '')
      end

      it 'should forget thing' do
        send_command('forget ENV345')
        expect(subject.redis.keys).to_not include('whohas_things:my_project:ENV345')
      end

      it 'should confirm' do
        send_command('forget ENV345')
        expect(replies.first).to eq("Poof! It's gone!")
      end
    end

    context 'when thing is unknown to bot' do
      before(:each) do
        subject.redis.del('whohas_things:my_project:ENV345')
      end

      it 'should reply with notification' do
        send_command('forget ENV345')
        expect(replies.first).to eq('Hmm, I do not know about ENV345')
      end
    end

    context 'when thing is in use by another user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV345', 'user', 'Carl')
      end

      it 'should leave the thing untouched' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('forget ENV345', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV345', 'user')).to eq('Carl')
      end

      it 'should reply with notification' do
        send_command('forget ENV345')
        expect(replies.first).to eq('Hmm, ENV345 is currently in use by Carl')
      end
    end

    context 'when thing is in use by user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV345', 'user', 'Alicia')
      end

      it 'should leave the thing untouched' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('forget ENV345', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV345', 'user')).to eq('Alicia')
      end

      it 'should reply with notification' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('forget ENV345', as: alicia)
        expect(replies.first).to eq('Hmm, you are currently using ENV345')
      end
    end
  end

  describe 'User claiming thing from other user' do
    context 'when thing is currently in use by specified user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Alicia')
      end

      it 'should mark thing as in use' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('wrestle ENV123 from Alicia', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to eq('Carl')
      end

      it 'should reply with confirmation' do
        send_command('wrestle ENV123 from Alicia')
        expect(replies.first).to eq("It's all yours!")
      end
    end

    context 'when thing is currently in use by a user other than the specified one' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Alicia')
      end

      it 'should leave the thing untouched' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('wrestle ENV123 from Ben', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to eq('Alicia')
      end

      it 'should reply with notification' do
        send_command('wrestle ENV123 from Ben')
        expect(replies.first).to eq('Hmm, ENV123 is currently in use by Alicia, not Ben')
      end
    end

    context 'when thing is not currently in use' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', nil)
      end

      it 'should leave the thing untouched' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('wrestle ENV123 from Ben', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to be_empty
      end

      it 'should reply with notification' do
        send_command('wrestle ENV123 from Ben')
        expect(replies.first).to eq('Hmm, ENV123 is not currently in use')
      end
    end

    context 'when thing is already marked as in use by requesting user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Carl')
      end

      it 'should leave the thing untouched' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('wrestle ENV123 from Ben', as: carl)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'user')).to eq('Carl')
      end

      it 'should reply with notification' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('wrestle ENV123 from Ben', as: carl)
        expect(replies.first).to eq('Hmm, you are already using ENV123')
      end
    end

    context 'when thing is unknown to bot' do
      before(:each) do
        subject.redis.del('whohas_things:my_project:ENV123')
      end

      it 'should reply with notification' do
        carl = Lita::User.create(123, name: 'Carl')
        send_command('wrestle ENV123 from Ben', as: carl)
        expect(replies.first).to eq('Hmm, I do not know about ENV123')
      end
    end
  end
  describe 'User describing a thing' do
    context 'when thing is currently in use by specified user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV123', 'user', 'Alicia')
      end

      it 'adds a description key' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('describe ENV123 location the moon', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV123', 'description'))
          .to eq({ 'location' => 'the moon' }.to_json)
        expect(replies.first).to eq('Description \'location\' set for ENV123')
      end

      it 'allows retrieving a description' do
        alicia = Lita::User.create(123, name: 'Alicia')
        subject.redis.hset(
          'whohas_things:my_project:ENV123',
          'description',
          { 'location' => 'the moon' }.to_json
        )
        send_command('describe ENV123', as: alicia)
        expect(replies.first).to eq('Here\'s what I know about ENV123')
        expect(replies.last).to eq(
          '/code ' + JSON.pretty_generate(
            'in use by' => 'Alicia',
            'location' => 'the moon'
          )
        )
      end
    end

    context 'when thing is unknown to bot' do
      before(:each) do
        subject.redis.del('whohas_things:my_project:ENV123')
      end

      it 'replies with a notification' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('describe ENV123', as: alicia)
        expect(replies.first).to eq('Hmm, I do not know about ENV123')
      end
    end

    context 'when thing is in use by another user' do
      before(:each) do
        subject.redis.hset('whohas_things:my_project:ENV234', 'user', 'Carl')
      end

      it 'leaves the thing untouched' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('describe ENV234 disposition sunny', as: alicia)
        expect(subject.redis.hget('whohas_things:my_project:ENV234', 'user')).to eq('Carl')
      end

      it 'replies with a notification' do
        alicia = Lita::User.create(123, name: 'Alicia')
        send_command('describe ENV234  disposition sunny', as: alicia)
        expect(replies.first).to eq(
          'I can\'t change the description for ENV234 while it\'s in use by Carl'
        )
      end

      it 'allows retrieving a description' do
        alicia = Lita::User.create(123, name: 'Alicia')
        subject.redis.hset(
          'whohas_things:my_project:ENV234',
          'description',
          { 'disposition' => 'cloudy' }.to_json
        )
        send_command('describe ENV234', as: alicia)
        expect(replies.first).to eq('Here\'s what I know about ENV234')
        expect(replies.last).to eq(
          '/code ' + JSON.pretty_generate(
            'in use by'   => 'Carl',
            'disposition' => 'cloudy'
          )
        )
      end
    end
  end
end
