package msi

import (
	"fmt"
	"syscall"
)

func GetProperty(property, msiPath string) (string, error) {
	// load msi.dll
	msiDll := syscall.NewLazyDLL("msi.dll")
	msiDllOpenDatabaseW := msiDll.NewProc("MsiOpenDatabaseW")
	msiDllDatabaseOpenViewW := msiDll.NewProc("MsiDatabaseOpenViewW")
	msiDllViewExecute := msiDll.NewProc("MsiViewExecute")
	msiDllViewFetch := msiDll.NewProc("MsiViewFetch")
	msiRecordGetString := msiDll.NewProc("MsiRecordGetStringW")
	msiDllViewClose := msiDll.NewProc("MsiViewClose")
	msiDllCloseHandle := msiDll.NewProc("MsiCloseHandle")

	// open the msi database
	var msiHandle syscall.Handle
	msiPathPtr, _ := syscall.UTF16PtrFromString(msiPath)
	ret, _, _ := msiDllOpenDatabaseW.Call(uintptr(unsafe.Pointer(msiPathPtr)), uintptr(0), uintptr(unsafe.Pointer(&msiHandle)))
	if ret != 0 {
		return "", fmt.Errorf("error opening msi database: %d", ret)
	}

	// create a query to get the property
	var query string = "SELECT Value FROM Property WHERE Property = '" + property + "'"
	queryPtr, _ := syscall.UTF16PtrFromString(query)
	var viewHandle syscall.Handle
	ret, _, _ = msiDllDatabaseOpenViewW.Call(uintptr(msiHandle), uintptr(unsafe.Pointer(queryPtr)), uintptr(unsafe.Pointer(&viewHandle)))
	if ret != 0 {
		return "", fmt.Errorf("error opening view: %d", ret)
	}

	// execute the query
	ret, _, _ = msiDllViewExecute.Call(uintptr(viewHandle), uintptr(0))
	if ret != 0 {
		return "", fmt.Errorf("error executing view: %d", ret)
	}

	// fetch the result
	var recordHandle syscall.Handle
	ret, _, _ = msiDllViewFetch.Call(uintptr(viewHandle), uintptr(unsafe.Pointer(&recordHandle)))
	if ret != 0 {
		return "", fmt.Errorf("error fetching view: %d", ret)
	}

	// get the size of the value
	var valueSize uint32 = 0
	ret, _, _ = msiRecordGetString.Call(uintptr(recordHandle), uintptr(1), uintptr(0), uintptr(unsafe.Pointer(&valueSize)))
	if ret != 0 {
		return "", fmt.Errorf("error getting string size: %d", ret)
	}

	// allocate a buffer for the value
	valueSize++ // add 1 for null terminator
	valueBuffer := make([]uint16, valueSize)

	// get the value
	ret, _, _ = msiRecordGetString.Call(uintptr(recordHandle), uintptr(1), uintptr(unsafe.Pointer(&valueBuffer[0])), uintptr(unsafe.Pointer(&valueSize)))
	if ret != 0 {
		return "", fmt.Errorf("error getting string data: %d", ret)
	}

	// close the view
	ret, _, _ = msiDllViewClose.Call(uintptr(viewHandle))
	if ret != 0 {
		return "", fmt.Errorf("error closing view: %d", ret)
	}

	// close the msi database
	ret, _, _ = msiDllCloseHandle.Call(uintptr(msiHandle))
	if ret != 0 {
		return "", fmt.Errorf("error closing msi database: %d", ret)
	}

	// return the value
	return syscall.UTF16ToString(valueBuffer), nil
}
