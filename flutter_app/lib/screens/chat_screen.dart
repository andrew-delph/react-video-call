// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter_app/models/chat_room_model.dart';

// Package imports:
import 'package:get/get.dart';

// Project imports:
import '../controllers/chat_controller.dart';
import '../widgets/app_menu_widget.dart';

class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppMenu(
        title: 'Chat',
        body: SingleChildScrollView(
            child: Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
              const Text(
                "Chat",
                style: TextStyle(
                  fontSize: 35.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Obx(() => Row(children: [
                    Column(
                      children: [
                        ...(() {
                          List<ChatRoomModel> chatRoomList =
                              controller.chatRoomMap.values.toList();

                          chatRoomList.sort((a, b) {
                            return a.latestChat!.compareTo(b.latestChat!);
                          });
                          return chatRoomList.map((chatroom) => TextButton(
                              onPressed: () {
                                controller.showChat(chatroom);
                              },
                              child: Text("${chatroom.target}")));
                        })(),
                      ],
                    ),
                    controller.obx(
                      (state) {
                        if (state != null) {
                          return Expanded(child: state);
                        } else {
                          return const Text("Select a chat room.");
                        }
                      },
                    )
                  ]))
            ]))));
  }
}
