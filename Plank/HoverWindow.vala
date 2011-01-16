//  
//  Copyright (C) 2011 Robert Dyer
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 

using Cairo;
using Gdk;
using Gtk;
using Pango;

using Plank.Services.Drawing;

namespace Plank
{
	public class HoverWindow : CompositedWindow
	{
		const int HoverHeight = 26;
		
		public string Text { get; set; }
		
		public HoverWindow ()
		{
			base.with_type (Gtk.WindowType.POPUP);
			
			set_accept_focus (false);
			can_focus = false;
			skip_pager_hint = true;
			skip_taskbar_hint = true;
			set_type_hint (WindowTypeHint.DOCK);
			
			notify["Text"].connect (invalidate);
			
			stick ();
			set_size_request (100, 30);
			
			show_all ();
		}
		
		public void move_hover (int item_x, int item_y)
		{
			var x = item_x - width_request / 2;
			var y = item_y - height_request - 10;
			
			Gdk.Rectangle monitor;
			get_screen ().get_monitor_geometry (get_screen ().get_monitor_at_point (item_x, item_y), out monitor);
			
			x = (int) Math.fmax (monitor.x, Math.fmin (x, monitor.x + monitor.width - width_request));
			y = (int) Math.fmax (monitor.y, Math.fmin (y, monitor.y + monitor.height - height_request));
			
			move (x, y);
		}
		
		void invalidate ()
		{
			background_buffer = null;
			draw_background ();
			
			queue_draw ();
		}
		
		PlankSurface background_buffer;
		
		void draw_background ()
		{
			if (Text == "" || Text == null)
				return;
			
			// calculate the text layout to find the size
			var layout = new Pango.Layout (pango_context_get ());
			
			var font_description = get_style ().font_desc;
			font_description.set_absolute_size ((int) (11 * Pango.SCALE));
			font_description.set_weight (Weight.BOLD);
			layout.set_font_description (font_description);
			
			layout.set_ellipsize (EllipsizeMode.END);
			layout.set_text (Text, -1);
			
			// make the buffer
			Pango.Rectangle ink_rect, logical_rect;
			layout.get_pixel_extents (out ink_rect, out logical_rect);
			if (logical_rect.width > 0.8 * Screen.get_default ().width ()) {
				layout.set_width ((int) (0.8 * Screen.get_default ().width () * Pango.SCALE));
				layout.get_pixel_extents (out ink_rect, out logical_rect);
			}
			
			var buffer = HoverHeight - logical_rect.height;
			
			set_size_request ((int) Math.fmax (HoverHeight, buffer + logical_rect.width), HoverHeight);
			background_buffer = new PlankSurface (width_request, height_request);
			background_buffer.Context.save ();
			
			// draw the background
			var gradient = new Pattern.linear (background_buffer.Width / 2.0, 0, background_buffer.Width / 2.0, background_buffer.Height);
			gradient.add_color_stop_rgba (0, 0.1647, 0.1647, 0.1647, 1);
			gradient.add_color_stop_rgba (1, 0.3176, 0.3176, 0.3176, 1);
			
			Drawing.draw_rounded_rect (background_buffer.Context, 1, 1, background_buffer.Width - 2, background_buffer.Height - 2, 3, 3);
			background_buffer.Context.set_source (gradient);
			background_buffer.Context.fill_preserve ();
			
			background_buffer.Context.set_source_rgba (0.1647, 0.1647, 0.1647, 1);
			background_buffer.Context.set_line_width (1.0);
			background_buffer.Context.stroke ();
			
			gradient = new Pattern.linear (background_buffer.Width / 2.0, 2, background_buffer.Width / 2.0, background_buffer.Height - 4);
			gradient.add_color_stop_rgba (0, 0.4392, 0.4392, 0.4392, 1);
			gradient.add_color_stop_rgba (0.2, 0.4392, 0.4392, 0.4392, 0);
			
			Drawing.draw_rounded_rect (background_buffer.Context, 2, 2, background_buffer.Width - 4, background_buffer.Height - 4, 3, 3);
			background_buffer.Context.set_source (gradient);
			background_buffer.Context.set_line_width (1.0);
			background_buffer.Context.stroke ();
			
			// draw the text
			background_buffer.Context.restore ();
			
			background_buffer.Context.move_to (buffer / 2, buffer / 2);
			background_buffer.Context.set_source_rgb (1, 1, 1);
			Pango.cairo_show_layout (background_buffer.Context, layout);
		}
		
		public override bool expose_event (EventExpose event)
		{
			if (background_buffer == null || background_buffer.Height != height_request || background_buffer.Width != width_request)
				draw_background ();
			
			if (background_buffer == null)
				return base.expose_event (event);
			
			var cr = cairo_create (event.window);
			
			cr.set_operator (Operator.SOURCE);
			cr.set_source_surface (background_buffer.Internal, 0, 0);
			cr.paint ();
			
			return true;
		}
	}
}
