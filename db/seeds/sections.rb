# sections マスタデータ(4レコード)
# 出典: 職業性ストレス簡易調査票(57項目)、厚生労働省
# 冪等性: find_or_initialize_by で code をキーに検索、update! で最新化

sections_data = [
  {
    code: "a",
    name: "仕事のストレス要因",
    intro_text: "あなたの仕事についてうかがいます。最もあてはまるものに○を付けてください。",
    display_order: 1
  },
  {
    code: "b",
    name: "心身のストレス反応",
    intro_text: "最近1か月間のあなたの状態についてうかがいます。最もあてはまるものに○を付けてください。",
    display_order: 2
  },
  {
    code: "c",
    name: "周囲のサポート",
    intro_text: "あなたの周りの方々についてうかがいます。最もあてはまるものに○を付けてください。",
    display_order: 3
  },
  {
    code: "d",
    name: "満足度",
    intro_text: "満足度について",
    display_order: 4
  }
]

sections_data.each do |attrs|
  section = Section.find_or_initialize_by(code: attrs[:code])
  section.assign_attributes(attrs)
  section.save!
end

puts "sections: #{Section.count} レコード投入完了"
