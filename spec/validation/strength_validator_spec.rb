require 'spec_helper'

class User
  include ActiveModel::Validations
  attr_accessor :password
end

class TestBaseStrength < User
  validates :password, password_strength: true
end

class TestStrengthWeakEntropy < User
  validates :password, password_strength: {min_entropy: 1, use_dictionary: true}
end

class TestStrengthStrongEntropy < User
  validates :password, password_strength: {min_entropy: 40, use_dictionary: true}
end

class TestStrengthLegacyStrongEntropy < User
  validates :password, password_strength: {min_entropy: 40, use_dictionary: true, every_dictionary_word: false}
end

class TestStrengthExtraWords < User
  validates :password, password_strength: {extra_dictionary_words: ['administrator'], use_dictionary: true}
end

class TestStrengthExtraWordsAsProc < User
  validates :password, password_strength: {extra_dictionary_words: ->(_user) { ['administrator'] }, use_dictionary: true}
end

class TestStrengthExtraWordsAsSymbol < User
  validates :password, password_strength: {extra_dictionary_words: :extra_words_array, use_dictionary: true}

  def extra_words_array
    ['administrator']
  end
end

class TestBaseStrengthAlternative < User
  validates_password_strength :password
end

module ActiveModel
  module Validations
    describe PasswordStrengthValidator do
      let(:base_strength) { TestBaseStrength.new }
      let(:weak_entropy) { TestStrengthWeakEntropy.new }
      let(:strong_entropy) { TestStrengthStrongEntropy.new }
      let(:legacy_strong_entropy) { TestStrengthLegacyStrongEntropy.new }
      let(:extra_words) { TestStrengthExtraWords.new }
      let(:extra_words_as_proc) { TestStrengthExtraWordsAsProc.new }
      let(:extra_words_as_symbol) { TestStrengthExtraWordsAsSymbol.new }
      let(:alternative_usage) { TestBaseStrengthAlternative.new }

      describe 'validations' do
        describe 'base strength' do
          describe 'invalid' do
            [
              nil,
              'password',
              '1234',
              'f0bar',
              'b@s3'
            ].each do |password|
              it "adds errors when password is '#{password}'" do
                base_strength.password = password
                base_strength.valid?
                expect(base_strength.errors[:password]).to eq(["is too weak"])
              end
            end
          end

          describe 'valid' do
            [
              'p@ssw0fdsafsdafrd',
              'b@se3ball rocks',
              'f0bar plus baz',
              'b@s3_9123as##!1?'
            ].each do |password|
              it "does not add errors when password is '#{password}'" do
                base_strength.password = password
                base_strength.valid?
                expect(base_strength.errors[:password]).to be_empty
              end
            end
          end
        end

        describe 'alternative usage' do
          describe 'invalid' do
            [
              'password',
              '1234',
              'f0bar',
              'b@s3'
            ].each do |password|
              it "adds errors when password is '#{password}'" do
                alternative_usage.password = password
                alternative_usage.valid?
                expect(alternative_usage.errors[:password]).to eq(["is too weak"])
              end
            end
          end

          describe 'valid' do
            [
              'p@ssw0fdsafsdafrd',
              'b@se3ball rocks',
              'f0bar plus baz',
              'b@s3_9123as##!1?'
            ].each do |password|
              it "does not add errors when password is '#{password}'" do
                alternative_usage.password = password
                alternative_usage.valid?
                expect(alternative_usage.errors[:password]).to be_empty
              end
            end
          end
        end

        describe 'entropy override' do
          describe 'lowered entropy' do
            describe 'valid' do
              [
                'password',
                '1234',
                'f0bar',
                'b@s3'
              ].each do |password|
                it "'#{password}' should be valid with lowered entropy requirement" do
                  weak_entropy.password = password
                  weak_entropy.valid?
                  expect(weak_entropy.errors[:password]).to be_empty
                end
              end
            end
          end

          describe 'increased entropy' do
            describe 'invalid' do
              [
                'p@ssw0fdsafsdafrd',
                'b@se3ball rocks',
                'f0bar plus baz',
                'b@s3_9123as##!1?',
                'P45$wordQw3rtyBaseb4llAbCdEfGhIjKlMnOpQrStUvWxYz'
              ].each do |password|
                it "'#{password}' should be invalid with increased entropy requirement" do
                  strong_entropy.password = password
                  strong_entropy.valid?
                  expect(strong_entropy.errors[:password]).to eq(["is too weak"])
                end
              end
            end
          end

          describe 'increased entropy but only reducing first dictionary word' do
            describe 'invalid' do
              [
                'p@ssw0fdsafsdafrd',
                'b@se3ball rocks',
                'f0bar plus baz',
                'b@s3_9123as##!1?',
              ].each do |password|
                it "'#{password}' should be invalid with increased entropy requirement" do
                  legacy_strong_entropy.password = password
                  legacy_strong_entropy.valid?
                  expect(legacy_strong_entropy.errors[:password]).to eq(["is too weak"])
                end
              end
            end

            describe 'valid' do
              it "'P45$wordQw3rtyBaseb4llAbCdEfGhIjKlMnOpQrStUvWxYz' is valid" do
                legacy_strong_entropy.password = 'P45$wordQw3rtyBaseb4llAbCdEfGhIjKlMnOpQrStUvWxYz'
                legacy_strong_entropy.valid?
                expect(legacy_strong_entropy.errors[:password]).to be_empty
              end
            end
          end
        end

        describe 'extra words' do
          it 'allows extra words to be specified as an option to the validation' do
            password = 'administratorWEQ@123'
            # Validate that without 'administrator' added to extra_dictionary_words
            # this password is considered strong
            weak_entropy.password = password
            expect(weak_entropy.valid?).to be_truthy
            # Now check that with 'administrator' added to extra_dictionary_words
            # in our model, the same password is considered weak.
            extra_words.password = password
            expect(extra_words.valid?).to be_falsey
            # Check that the extra words configuration can be passed as a proc
            extra_words_as_proc.password = password
            expect(extra_words_as_proc.valid?).to be_falsey
            # Check that the extra words configuration can be passed as a symbol,
            # which we then turn into a method call
            extra_words_as_symbol.password = password
            expect(extra_words_as_symbol.valid?).to be_falsey
          end
        end
      end
    end
  end
end
