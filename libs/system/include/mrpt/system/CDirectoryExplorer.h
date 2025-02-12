/* +------------------------------------------------------------------------+
   |                     Mobile Robot Programming Toolkit (MRPT)            |
   |                          https://www.mrpt.org/                         |
   |                                                                        |
   | Copyright (c) 2005-2021, Individual contributors, see AUTHORS file     |
   | See: https://www.mrpt.org/Authors - All rights reserved.               |
   | Released under BSD License. See: https://www.mrpt.org/License          |
   +------------------------------------------------------------------------+ */
#pragma once

#include <mrpt/system/os.h>

#include <deque>

namespace mrpt::system
{
#define FILE_ATTRIB_ARCHIVE 0x0020
#define FILE_ATTRIB_DIRECTORY 0x0010

/** This class allows the enumeration of the files/directories that exist into a
 * given path.
 *  The only existing method is "explore" and returns the list of found files &
 * directories.
 *  Refer to the example in /samples/UTILS/directoryExplorer
 *
 *  \sa CFileSystemWatcher
 * \ingroup mrpt_system_grp
 */
class CDirectoryExplorer
{
   public:
	/** This represents the information about each file.
	 * \sa
	 */
	struct TFileInfo
	{
		std::string name;  //!< The file name part only, without path.
		std::string wholePath;	//!< Full, absolute path of the file
		time_t accessTime, modTime;	 //!< Access and modification times.
		bool isDir = false, isSymLink = false;
		uint64_t fileSize = 0;	//!< File size [bytes]
	};

	/** The list type used in "explore".
	 * \sa explore
	 */
	using TFileInfoList = std::deque<TFileInfo>;

   public:
	/** The path of the directory to examine must be passed to this constructor,
	 * among the
	 *  According to the following parameters, the object will collect the list
	 * of files, which
	 *   can be modified later through other methods in this class.
	 * \param path The path to examine (IT MUST BE A DIRECTORY), e.g
	 * "d:\temp\", or "/usr/include/"
	 * \param mask One or the OR'ed combination of the values
	 * "FILE_ATTRIB_ARCHIVE" and "FILE_ATTRIB_DIRECTORY", depending on what file
	 * types do you want in the list (These values are platform-independent).
	 * \param outList The list of found files/directories is stored here.
	 * \sa sortByName
	 */
	static TFileInfoList explore(
		const std::string& path, const unsigned long mask);

	/// \overload \deprecated Prefer the return-by-value signature (MRPT 2.3.1)
	static void explore(
		const std::string& path, const unsigned long mask,
		TFileInfoList& outList)
	{
		outList = explore(path, mask);
	}

	/** Sort the file entries by name, in ascending or descending order
	 */
	static void sortByName(TFileInfoList& lstFiles, bool ascendingOrder = true);

	/** Remove from the list of files those whose extension does not coincide
	 * (without case) with the given one.
	 *  Example:  filterByExtension(lst,"txt");
	 */
	static void filterByExtension(
		TFileInfoList& lstFiles, const std::string& extension);

};	// End of class def.

}  // namespace mrpt::system
