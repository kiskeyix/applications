#!/usr/bin/env ruby
=begin
Luis Mondesi <lemsx1@gmail.com> 
2008-12-25 14:05 EST 

Un programa simple para adivinar un numero entre 1 y 100

=end

require 'gtk2'

a=rand(100)

i = 0
box = Gtk::VBox.new(false,0)
status = Gtk::Statusbar.new()

label = Gtk::Label.new("Dame un numero entre 1 y 100:", true)
entry = Gtk::Entry.new()
label.mnemonic_widget = entry

button = Gtk::Button.new("Elige")
button.signal_connect("clicked") {
   n = entry.text().to_i
   if a < n or a > n
      i += 1
      status.push(status.get_context_id("status"),"#{i}. #{n} es muy grande") if n > a
      status.push(status.get_context_id("status"),"#{i}. #{n} es muy chiquito") if n < a
   else
      congrats = "Felicidades!! Lo encontraste!"
      status.push(status.get_context_id("status"),congrats)
      dialog = Gtk::MessageDialog.new(nil,
      Gtk::Dialog::DESTROY_WITH_PARENT,
      Gtk::MessageDialog::INFO,
      Gtk::MessageDialog::BUTTONS_CLOSE,
      "%s" % congrats)
      dialog.run
      dialog.destroy
      Gtk.main_quit
   end
}

box.pack_start(label, false, false, 0)
box.pack_start(entry, false, false, 0)
box.pack_start(button, false, false, 0)
box.pack_start(status, false, false, 0)

window = Gtk::Window.new
window.signal_connect("delete_event") {
   puts "delete event occurred"
   false
}

window.signal_connect("destroy") {
   puts "destroy event occurred"
   Gtk.main_quit
}

window.border_width = 10
window.add(box)
window.show_all

Gtk.main
