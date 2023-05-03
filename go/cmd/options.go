package main

import (
	"api"
	"errors"

	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
)

var options = []flutter.Option{
	flutter.WindowInitialDimensions(800, 1280),
	flutter.AddPlugin(&uploadPlugin{}),
}

type uploadPlugin struct {
	flutter.Plugin
}

func (u *uploadPlugin) InitPlugin(m plugin.BinaryMessenger) error {
	ch := plugin.NewMethodChannel(m, "org.gallery", plugin.StandardMethodCodec{})
	ch.HandleFunc("addFiles", func(message interface{}) (interface{}, error) {
		if _, ok := message.(string); !ok {
			return nil, errors.New("the argument should be a string")
		}

		return nil, api.UploadFile(message.(string))
	})

	return nil
}
