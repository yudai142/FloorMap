namespace :floor_plan_templates do
  desc "プレビュー画像がない上面図テンプレートに画像を生成して添付する"
  task backfill_previews: :environment do
    generated = 0

    FloorPlanTemplate.includes(:template_seats).find_each do |template|
      next if template.preview_image.attached?

      svg = FloorPlanPreviewSvg.new(template).render
      template.preview_image.attach(io: StringIO.new(svg), filename: "preview.svg", content_type: "image/svg+xml")
      generated += 1
      puts "generated preview for template ##{template.id}"
    end

    puts "done: #{generated} preview(s) generated"
  end
end
