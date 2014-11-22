describe "service/Env", ->
  beforeEach ->
    module "service/Env"

    inject (env) =>
      @env = env
      return
    return

  it "プロパティの変更は許可されない", ->
    expect(Object.isFrozen(@env)).toBeTruthy()
    return

  describe ".test", ->
    it "テスト環境ではtrueを示す", () ->
      expect(@env.test).toBeTruthy()
      return
    return

  describe ".develop", ->
    it "テスト環境ではfalseを示す", () ->
      expect(@env.develop).toBeFalsy()
      return
    return

  describe ".production", ->
    it "テスト環境ではfalseを示す", () ->
      expect(@env.production).toBeFalsy()
      return
    return

  return

