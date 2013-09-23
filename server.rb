require 'sinatra'
require 'stretcher'

configure do
  ES = Stretcher::Server.new('http://localhost:9200')
end

class Products
  def self.match(text)
    ES.index(:products).search size: 1000, query: {
      multi_match: { query: text, fields: [:title, :description] }
    }
  end
end

get "/" do
  erb :index
end

get "/:search" do
  erb :result, locals: { products: Products.match(params[:search]) }
end

post "/" do
  unless ES.index(:products).exists?
    # create index if not exists
    ES.index(:products).create(mappings: {
      product: {
        properties: {
          title: {type: :string},
          price: {type: :integer},
          description: {type: :string}
        }
      }
    })
  end

  # insert data
  ES.index(:products).type(:product).post({
    title: params[:title],
    price: params[:price],
    description: params[:description]
  })
end

__END__
@@ layout
<!DOCTYPE html>
<html>
<head>
  <title>Test elasticsearch</title>
</head>
<body>
  <%= yield %>
</body>
</html>

@@index
<strong>Add product</strong>
<form action="/" method="post">
<input type="text" name="title" placeholder="Title"><br>
<input type="text" name="price" placeholder="Price"><br>
<textarea name="description" cols="40" rows="5"></textarea><br>
<input type="submit">
</form>

@@result
<% if products %>
  <ul>
  <% products.results.each do |product| %>
    <li>
      <strong><%= product[:title] %></strong><br>
      <%= product[:description] %>
    </li>
  <% end %>
  </ul>
<% end %>
