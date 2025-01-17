require 'spec_helper'

module StrongPassword
  describe DictionaryAdjuster do
    describe '#is_strong?' do
      let(:subject) { DictionaryAdjuster.new }

      it 'returns true if the calculated entropy is >= the minimum' do
        allow(subject).to receive_messages(adjusted_entropy: 18)
        expect(subject.is_strong?('password')).to be_truthy
      end

      it 'returns false if the calculated entropy is < the minimum' do
        allow(subject).to receive_messages(adjusted_entropy: 17)
        expect(subject.is_strong?('password')).to be_falsey
      end
    end

    describe '#is_weak?' do
      let(:subject) { DictionaryAdjuster.new }

      it 'returns the opposite of is_strong?' do
        allow(subject).to receive_messages(is_strong?: true)
        expect(subject.is_weak?('password')).to be_falsey
      end
    end

    describe '#adjusted_entropy' do
      before(:each) { allow(NistBonusBits).to receive_messages(bonus_bits: 0) }
      let(:base_adjuster) { DictionaryAdjuster.new(config) }

      describe 'only checking the first dictionary word' do
        let(:config) { { every_dictionary_word: false } }

        it 'checks against all variants of a given password' do
          password = 'password'
          expect(PasswordVariants).to receive(:all_variants).with(password).and_return([])
          subject.adjusted_entropy(password)
        end

        {
          'bnm,./' => 14, # Qwerty string should not get adjusted by dictionary adjuster
          'h#e0zbPas' => 19.5, # Random string should not get adjusted by dictionary adjuster
          'password' => 4, # Adjusts common dictionary words
          'E_!3password' => 11.5, # Adjusts common dictionary words regardless of placement
          'h#e0zbPas 32e2i81 password' => 31.0625, # Even if there are multiple words
          '123456' => 4, # Even if they are also qwerty strings
          'password123456' => 14, # But only drops the first matched word
          'asdf)asdf' => 14, # Doesn't break with parens
          'asdf[]asdf' => 16 # Doesn't break with []s
        }.each do |password, bits|
          it "returns #{bits} for '#{password}'" do
            expect([password, base_adjuster.adjusted_entropy(password)]).to eq([password, bits])
          end
        end

        it 'allows extra words to be provided as an array' do
          password = 'administratorWEQ@123'
          base_entropy = base_adjuster.adjusted_entropy(password)
          enhanced_adjuster = DictionaryAdjuster.new config.merge(extra_dictionary_words: ['administrator'])
          expect(enhanced_adjuster.adjusted_entropy(password)).to be < base_entropy
        end

        it 'allows minimum word length to be adjusted' do
          password = '6969'
          base_entropy = base_adjuster.adjusted_entropy(password)
          weakened_adjuster = DictionaryAdjuster.new config.merge(min_word_length: 6)
          # If we increase the min_word_length above the length of the password we should get a higher entropy
          expect(weakened_adjuster.adjusted_entropy(password)).to be > base_entropy
        end
      end

      describe 'checking every dictionary word' do
        let(:config) { { } } # this is the default

        it 'checks against all variants of a given password' do
          password = 'password'
          expect(PasswordVariants).to receive(:all_variants).with(password).and_return([])
          subject.adjusted_entropy(password)
        end

        {
          'bnm,./' => 14, # Qwerty string should not get adjusted by dictionary adjuster
          'h#e0zbPas' => 19.5, # Random string should not get adjusted by dictionary adjuster
          'password' => 4, # Adjusts common dictionary words
          'E_!3password' => 11.5, # Adjusts common dictionary words regardless of placement
          'h#e0zbPas 32e2i81 password' => 31.0625, # Even if there are multiple words
          '123456' => 4, # Even if they are also qwerty strings
          'password123456' => 7.5, # No longer drops only the first matched word
          'asdf)asdf' => 7.5, # Doesn't break with parens
          'asdf[]asdf' => 9.5 # Doesn't break with []s
        }.each do |password, bits|
          it "returns #{bits} for '#{password}'" do
            expect([password, base_adjuster.adjusted_entropy(password)]).to eq([password, bits])
          end
        end

        it 'allows extra words to be provided as an array' do
          password = 'administratorWEQ@123'
          base_entropy = base_adjuster.adjusted_entropy(password)
          enhanced_adjuster = DictionaryAdjuster.new config.merge(extra_dictionary_words: ['administrator'])
          expect(enhanced_adjuster.adjusted_entropy(password)).to be < base_entropy
        end

        it 'allows minimum word length to be adjusted' do
          password = '6969'
          base_entropy = base_adjuster.adjusted_entropy(password)
          weakened_adjuster = DictionaryAdjuster.new config.merge(min_word_length: 6)
          # If we increase the min_word_length above the length of the password we should get a higher entropy
          expect(weakened_adjuster.adjusted_entropy(password)).to be > base_entropy
        end
      end
    end
  end
end
