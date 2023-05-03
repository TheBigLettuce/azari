package api

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"reflect"
	"strings"
)

func closeFiles(f []*os.File) {
	for _, file := range f {
		if file != nil {
			file.Close()
		}
	}
}

func UploadFile(mes string) error {
	var m map[string]interface{}
	if err := json.Unmarshal([]byte(mes), &m); err != nil {
		return err
	}

	typ, ok := m["type"].(float64)
	if !ok {
		return fmt.Errorf("invalid type value in the message map, need float64, got %s", reflect.TypeOf(m["type"]).String())
	}

	filePathsIf, ok := m["files"].([]interface{})
	if !ok {
		return errors.New("invalid files value in the message map, need []string")
	}

	var forcedDir string

	if _, ok := m["forcedDir"]; ok {
		forcedDir, ok = m["forcedDir"].(string)
		if !ok {
			return errors.New("invalid forcedDir value in the message map, need string")
		}
	}

	deviceId, ok := m["deviceId"].(string)
	if !ok {
		return errors.New("invalid deviceId value in the message map, need string")
	}

	baseDirectory, ok := m["baseDirectory"].(string)
	if !ok {
		return errors.New("invalid baseDirectory value in the message map, need string")
	}

	serverAddr, ok := m["serverAddress"].(string)
	if !ok {
		return errors.New("invalid serverAddress value in the message map, need string")
	}

	filePaths := make([]string, len(filePathsIf))
	for indx, path := range filePathsIf {
		filePaths[indx], ok = path.(string)
		if !ok {
			return errors.New("one of the files slice is not a string")
		}

		if forcedDir == "" {
			if !strings.HasPrefix(filePaths[indx], baseDirectory) {
				return errors.New("path does not begin with the base directory")
			}

			filePaths[indx] = strings.Trim(strings.TrimPrefix(filePaths[indx], baseDirectory), "/")
		}
	}

	files := make([]*os.File, len(filePaths))

	for indx, path := range filePaths {
		var f *os.File
		var err error
		if forcedDir == "" {
			f, err = os.Open(filepath.Join(baseDirectory, path))
		} else {
			f, err = os.Open(path)
		}
		if err != nil {
			closeFiles(files)
			return fmt.Errorf("while opening a file: %w", err)
		}

		files[indx] = f
	}
	defer closeFiles(files)

	type addFile struct {
		Name string `json:"name"`
		Dir  string `json:"dir"`
		Size int64  `json:"size"`

		Type int `json:"type"`
	}

	addFiles := make([]addFile, len(files))

	size := int64(0)

	for indx, f := range files {
		fstat, err := f.Stat()
		if err != nil {
			return fmt.Errorf("file: %w", err)
		}

		if fstat.IsDir() {
			return errors.New("file: some of the files is a directory")
		}

		size += fstat.Size()

		addFiles[indx] = addFile{
			Name: filepath.Base(f.Name()),
			Size: fstat.Size(),
			Type: int(typ),
		}

		if forcedDir != "" {
			addFiles[indx].Dir = forcedDir
		} else {
			addFiles[indx].Dir = filepath.Dir(filePaths[indx])
		}
	}

	byt, err := json.Marshal(addFiles)
	if err != nil {
		return fmt.Errorf("while marshalling: %w", err)
	}

	fio, njson := newFilesW(byt, files)
	size += int64(njson)

	req, err := http.NewRequest("POST", serverAddr+"/add/files", fio)
	if err != nil {
		return fmt.Errorf("while making a request: %w", err)
	}

	req.ContentLength = size
	req.Header.Add("Content-Type", "application/octet-stream")
	req.Header.Add("deviceId", deviceId)

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("response: %w", err)
	} else if res.StatusCode != http.StatusOK {
		return errors.New("response: status not ok")
	}

	return nil
}

func newFilesW(json []byte, files []*os.File) (io.Reader, int) {
	buf := make([]byte, binary.MaxVarintLen64)
	binary.PutUvarint(buf, uint64(len(json)))

	nWithJson := make([]byte, 0, len(buf)+len(json))
	nWithJson = append(nWithJson, buf...)
	nWithJson = append(nWithJson, json...)

	return io.MultiReader(append([]io.Reader{bytes.NewReader(nWithJson)}, func() []io.Reader {
		ret := make([]io.Reader, len(files))
		for ind, f := range files {
			ret[ind] = f
		}

		return ret
	}()...)...), len(nWithJson)
}
