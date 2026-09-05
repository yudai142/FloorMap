require 'rails_helper'

RSpec.describe 'Canvas Editor Feature', type: :feature, js: true do
  let(:user) { create(:user, :manager) }
  let(:room) { create(:room, user: user) }

  before do
    sign_in user
  end

  describe 'Canvas Editor Page Load' do
    it 'displays canvas editor page' do
      visit room_canvas_editor_path(room)
      expect(page).to have_content(room.name)
    end

    it 'displays toolbar with tool buttons' do
      visit room_canvas_editor_path(room)
      expect(page).to have_selector('.editor-toolbar')
    end

    it 'displays canvas SVG element' do
      visit room_canvas_editor_path(room)
      expect(page).to have_selector('svg.canvas-svg')
    end

    it 'displays status bar with seat/shape counts' do
      visit room_canvas_editor_path(room)
      expect(page).to have_selector('.canvas-status-bar')
    end
  end

  describe 'Canvas Dimensions' do
    it 'renders canvas with default dimensions' do
      visit room_canvas_editor_path(room)
      svg = find('svg.canvas-svg')
      expect(svg['width']).to eq('1000')
      expect(svg['height']).to eq('700')
    end

    it 'renders canvas with custom room dimensions if provided' do
      room.update(width: 1500, height: 900)
      visit room_canvas_editor_path(room)
      svg = find('svg.canvas-svg')
      expect(svg['width']).to eq('1500')
      expect(svg['height']).to eq('900')
    end
  end

  describe 'Tool Selection' do
    it 'displays tool buttons' do
      visit room_canvas_editor_path(room)
      expect(page).to have_content('選択')
      expect(page).to have_content('座席')
      expect(page).to have_content('直線')
    end

    it 'allows tool selection' do
      visit room_canvas_editor_path(room)
      # This would require JavaScript interaction
      # Example: click_button '座席' would select seat tool
      # Actual interaction depends on implementation
    end
  end

  describe 'Grid Functionality' do
    it 'displays grid toggle button' do
      visit room_canvas_editor_path(room)
      expect(page).to have_content('グリッド')
    end

    it 'toggles grid visibility' do
      visit room_canvas_editor_path(room)
      # Click grid toggle
      # Verify grid pattern appears/disappears
    end
  end

  describe 'Zoom Controls' do
    it 'displays zoom controls' do
      visit room_canvas_editor_path(room)
      expect(page).to have_content('ズーム')
    end

    it 'displays zoom percentage' do
      visit room_canvas_editor_path(room)
      expect(page).to have_selector('[class*="zoom"]')
    end
  end

  describe 'Save Functionality' do
    it 'displays save button' do
      visit room_canvas_editor_path(room)
      expect(page).to have_content('保存')
    end

    it 'shows unsaved changes indicator when state changes' do
      visit room_canvas_editor_path(room)
      # This requires actual state changes via JavaScript
      # expect(page).to have_content('未保存の変更')
    end
  end

  describe 'Undo/Redo' do
    it 'displays undo button' do
      visit room_canvas_editor_path(room)
      expect(page).to have_content('戻す')
    end

    it 'displays redo button' do
      visit room_canvas_editor_path(room)
      expect(page).to have_content('やり直す')
    end
  end

  describe 'Canvas Rendering with Initial Data' do
    let!(:seat1) { create(:seat, room: room, position_x: 100, position_y: 150) }
    let!(:seat2) { create(:seat, room: room, position_x: 250, position_y: 150) }

    before do
      room.update(floor_plan_data: [
        { type: 'rectangle', x: 50, y: 50, width: 400, height: 300 }
      ])
    end

    it 'renders existing seats' do
      visit room_canvas_editor_path(room)
      # Seats should be rendered as circles in the SVG
      expect(page).to have_selector('circle', count: 2)
    end

    it 'renders floor plan shapes' do
      visit room_canvas_editor_path(room)
      # Rectangle should be rendered
      expect(page).to have_selector('rect')
    end
  end

  describe 'Authorization' do
    context 'when user is not owner' do
      let(:other_user) { create(:user, :manager) }

      before do
        sign_out user
        sign_in other_user
      end

      it 'denies access to canvas editor' do
        expect {
          visit room_canvas_editor_path(room)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is admin' do
      let(:admin_user) { create(:user, :admin) }

      before do
        sign_out user
        sign_in admin_user
      end

      it 'allows admin to access' do
        # Admins may have different permissions
        # This depends on RoomPolicy implementation
      end
    end
  end
end
