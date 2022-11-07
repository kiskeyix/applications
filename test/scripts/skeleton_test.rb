require "test_helper"

describe :skeleton do
  it 'should instantiate sample' do
    require_relative '../../share/vim/skeleton'
    obj = MyExample.new
    _(obj).must_be_instance_of MyExample
  end
end
