defmodule Sakusen.Storage.S3Test do
  use ExUnit.Case, async: true

  alias Sakusen.Storage.S3

  @config %{
    backend: :s3,
    endpoint: "https://s3.example.com",
    region: "auto",
    bucket: "media",
    access_key_id: "AKIDEXAMPLE",
    secret_access_key: "secret",
    public_url: "https://cdn.example.com/"
  }

  test "put/4 sends a signed PUT to the path-style object url" do
    test_pid = self()

    Req.Test.stub(S3, fn conn ->
      send(test_pid, {:request, conn.method, conn.request_path, conn.req_headers})
      Plug.Conn.send_resp(conn, 200, "")
    end)

    assert :ok = S3.put(@config, "thumbnail/ab/cd/abcd.webp", {:data, "webp"}, "image/webp")

    assert_receive {:request, "PUT", "/media/thumbnail/ab/cd/abcd.webp", headers}
    assert {"content-type", "image/webp"} in headers
    assert {"authorization", authorization} = List.keyfind(headers, "authorization", 0)
    assert authorization =~ "AWS4-HMAC-SHA256"
  end

  test "url/2 joins the public url and the key" do
    assert S3.url(@config, "original/ab/cd/abcd.png") ==
             "https://cdn.example.com/original/ab/cd/abcd.png"
  end
end
